use std::collections::HashMap;
use std::fs;

use anyhow::Result;
use mlua::prelude::*;
use serde::{Deserialize, Serialize};

use crate as lib;

#[derive(Serialize, Deserialize)]
struct CitationItem {
    entry: serde_json::Value,
    csl_formatted_citation: Option<String>,
}

#[derive(Serialize, Deserialize)]
struct LuaSourceProcessRequest {
    cache_dir: String,
    source_type: String,
    source_path: String,
    csl_style: Option<String>,
    csl_locale: Option<String>,
}
impl LuaSourceProcessRequest {
    fn get_key(&self) -> String {
        format!(
            "{}-{}-{}-{}",
            self.source_type,
            self.source_path,
            self.csl_style.as_deref().unwrap_or("None"),
            self.csl_locale.as_deref().unwrap_or("None")
        )
    }

    fn is_cache_valid(&self, key: &str) -> Result<(bool, Option<cacache::Metadata>)> {
        let metadata = fs::metadata(&self.source_path)?;
        let last_mod_str = metadata
            .modified()
            .expect("File exists, must be able to read modified timestamp")
            .duration_since(std::time::UNIX_EPOCH)
            .expect("file modified later than Unix epoch")
            .as_millis();

        let metadata = cacache::metadata_sync(&self.cache_dir, key)?;
        Ok(metadata.map_or_else(
            || (false, None),
            |metadata| (last_mod_str <= metadata.time, Some(metadata)),
        ))
    }

    fn process(&self) -> Result<String> {
        let source = match self.source_type.as_str() {
            "bibtex" => lib::Source::Bibtex {
                path: self.source_path.clone(),
            },
            "biblatex" => lib::Source::BibLatex {
                path: self.source_path.clone(),
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

        if let Some(style) = &self.csl_style {
            let bibliography = lib::source_to_bibliography(&lib::SourceBibliographyRequest {
                source,
                bibliography_config: lib::BibliographyConfig {
                    csl_style: String::from(style),
                    csl_locale: self.csl_locale.as_ref().map(String::from),
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

    fn process_cached(&self) -> Result<String> {
        let key = self.get_key();

        let (cache_valid, cache_metadata) = self.is_cache_valid(&key)?;
        if cache_valid {
            let data = match cacache::read_sync(&self.cache_dir, &key) {
                Ok(data) => Ok(Some(data)),
                Err(e) => match e {
                    cacache::Error::EntryNotFound(_, _) => Ok(None),
                    _ => Err(e),
                },
            }?;
            if let Some(data) = data {
                return Ok(String::from_utf8(data)?);
            }
        }

        if let Some(metadata) = cache_metadata {
            cacache::remove_hash_sync(&self.cache_dir, &metadata.integrity)?;
        }

        let result = self.process()?;
        cacache::write_sync(&self.cache_dir, key, &result)?;
        Ok(result)
    }
}

fn lua_process_source(lua: &Lua, request: LuaValue) -> LuaResult<String> {
    let request: LuaSourceProcessRequest = lua.from_value(request)?;
    Ok(request.process_cached()?)
}

fn lua_is_source_cache_valid(lua: &Lua, request: LuaValue) -> LuaResult<bool> {
    let request: LuaSourceProcessRequest = lua.from_value(request)?;
    Ok(request.is_cache_valid(&request.get_key())?.0)
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
