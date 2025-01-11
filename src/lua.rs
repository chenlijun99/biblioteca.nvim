use std::collections::HashMap;
use std::fs;

use anyhow::Result;
use cached::{proc_macro::io_cached, IOCached};
use serde::{Deserialize, Serialize};

use mlua::prelude::*;

use crate as lib;

#[derive(Serialize, Deserialize)]
struct CitationItem {
    entry: serde_json::Value,
    csl_formatted_citation: Option<String>,
}

fn process_source(
    name: &str,
    path: &str,
    csl_style: Option<&str>,
    csl_locale: Option<&str>,
) -> Result<String> {
    let source = match name {
        "bibtex" => lib::Source::Bibtex {
            path: String::from(path),
        },
        "biblatex" => lib::Source::BibLatex {
            path: String::from(path),
        },
        _ => todo!(),
    };
    let mut result = HashMap::new();

    let value = lib::source_to_json(&source).unwrap();
    for entry in value.into_iter() {
        result.insert(
            entry.0,
            CitationItem {
                entry: entry.1,
                csl_formatted_citation: None,
            },
        );
    }

    if let Some(style) = csl_style {
        let bibliography = lib::source_to_bibliography(&lib::SourceBibliographyRequest {
            source,
            bibliography_config: lib::BibliographyConfig {
                csl_style: String::from(style),
                csl_locale: csl_locale.map(String::from),
                strip_ansi: false,
            },
        })
        .unwrap();
        for entry in bibliography.into_iter() {
            result
                .entry(entry.0)
                .and_modify(|item| item.csl_formatted_citation = Some(entry.1));
        }
    }

    Ok(serde_json::to_string(&result).expect("JSON serialization must not fail"))
}

#[io_cached(
    map_error = r##"|e| e"##,
    disk = true,
    sync_to_disk_on_cache_change = true,
    key = "String",
    convert = r#"{_computed_key.to_owned()}"#
)]
fn process_source_cached(
    _computed_key: &str,
    name: &str,
    path: &str,
    csl_style: Option<&str>,
    csl_locale: Option<&str>,
) -> Result<String> {
    return process_source(name, path, csl_style, csl_locale);
}

type LuaSourceProcessRequest = (String, String, Option<String>, Option<String>);
fn get_request_key(request: &LuaSourceProcessRequest) -> Result<String, std::io::Error> {
    let metadata = fs::metadata(&request.1)?;
    let last_mod_str = metadata
        .modified()
        .expect("File exists, must be able to read modified timestamp")
        .duration_since(std::time::UNIX_EPOCH)
        .expect("file modified later than Unix epoch")
        .as_secs()
        .to_string();

    Ok(format!(
        "{}-{}-{}-{}-{}",
        request.0,
        request.1,
        last_mod_str,
        request.2.as_deref().unwrap_or("None"),
        request.3.as_deref().unwrap_or("None")
    ))
}

/// Returns serialized JSON. Thus can be invoked also in Lua worker threads
/// and have the return value deserialized in the main thread.
fn lua_process_source(_: &Lua, request: LuaSourceProcessRequest) -> LuaResult<String> {
    let key = get_request_key(&request)?;

    let result = process_source_cached(
        &key,
        &request.0,
        &request.1,
        request.2.as_deref(),
        request.3.as_deref(),
    )?;

    Ok(result)
}

fn lua_is_source_cache_valid(_: &Lua, request: LuaSourceProcessRequest) -> LuaResult<bool> {
    let key = get_request_key(&request)?;
    let cache_exists = (*PROCESS_SOURCE_CACHED)
        .cache_get(&key)
        .is_ok_and(|value| value.is_some());

    Ok(cache_exists)
}

/// Exported Lua module
///
/// NOTE: the name of this function must match the name of the shared
/// library file that in the end is used in lua via `require()`.
#[mlua::lua_module]
fn biblioteca_rust(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("process_source", lua.create_function(lua_process_source)?)?;
    exports.set(
        "is_source_cache_valid",
        lua.create_function(lua_is_source_cache_valid)?,
    )?;
    Ok(exports)
}
