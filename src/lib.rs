use std::collections::HashMap;
use std::fs;
use std::io;

use hayagriva::archive;
use hayagriva::Entry;
use serde::{Deserialize, Serialize};
use serde_json;
use thiserror::Error;

use hayagriva::citationberg::{IndependentStyle, LocaleCode};
use hayagriva::io as hayagriva_io;
use hayagriva::{
    BibliographyDriver, BibliographyRequest, BufWriteFormat, CitationItem, CitationRequest,
};

#[derive(Debug, clap::Subcommand)]
pub enum Source {
    Bibtex {
        path: String,
    },
    #[command(name = "biblatex")]
    BibLatex {
        path: String,
    },
    CslJson {
        path: String,
    },
}

#[derive(Debug, clap::Args)]
pub struct BibliographyConfig {
    pub csl_style: String,
    pub csl_locale: Option<String>,
    #[clap(long)]
    pub strip_ansi: bool,
}

#[derive(Debug, clap::Args)]
pub struct SourceBibliographyRequest {
    #[command(subcommand, name = "source type")]
    pub source: Source,
    #[command(flatten)]
    pub bibliography_config: BibliographyConfig,
}

#[derive(Error, Debug)]
pub enum BibliotecaProcessSourceError {
    #[error("Cannot read from source")]
    SourceIoError(#[from] io::Error),
    #[error("Source content invalid")]
    SourceContentError(String),
    #[error("Unknown error")]
    Unknown,
}

fn get_citations<'a, I: Iterator<Item = &'a Entry>>(
    entries: I,
    config: &BibliographyConfig,
) -> HashMap<String, String> {
    let style = match archive::ArchivedStyle::by_name(&config.csl_style)
        .unwrap()
        .get()
    {
        hayagriva::citationberg::Style::Independent(v) => v,
        hayagriva::citationberg::Style::Dependent(_) => panic!("Specified style is dependent",),
    };
    let locales = archive::locales();

    let mut result = HashMap::new();

    let mut driver = BibliographyDriver::new();
    for entry in entries {
        let items = vec![CitationItem::with_entry(entry)];
        driver.citation(CitationRequest::from_items(items, &style, &locales));
    }

    let rendered = driver.finish(BibliographyRequest {
        style: &style,
        locale: None,
        locale_files: &locales,
    });

    for row in rendered.bibliography.map(|b| b.items).unwrap_or_default() {
        let mut cit = String::new();

        //if let Some(prefix) = row.first_field {
        //cit.push_str(&prefix.to_string());
        //}

        let content = if config.strip_ansi {
            format!("{:#}", row.content)
        } else {
            format!("{:}", row.content)
        };
        cit.push_str(&content);

        result.insert(row.key, cit);
    }

    result
}

type JsonObject = serde_json::Map<String, serde_json::Value>;

fn bib_source_to_json(path: &str) -> Result<JsonObject, BibliotecaProcessSourceError> {
    let contents = fs::read_to_string(path)?;
    let bib = hayagriva_io::from_biblatex_str(&contents).unwrap();
    let value = serde_json::to_value(bib).unwrap();
    if let serde_json::Value::Object(obj) = value {
        Ok(obj)
    } else {
        panic!("Expected JSON object");
    }
}

pub fn source_to_json(source: &Source) -> Result<JsonObject, BibliotecaProcessSourceError> {
    match source {
        Source::Bibtex { path } | Source::BibLatex { path } => bib_source_to_json(path),
        Source::CslJson { path } => todo!(),
    }
}

pub fn source_to_bibliography(
    request: &SourceBibliographyRequest,
) -> Result<HashMap<String, String>, BibliotecaProcessSourceError> {
    let library = match &request.source {
        Source::Bibtex { path } | Source::BibLatex { path } => {
            let contents = fs::read_to_string(path)?;
            hayagriva_io::from_biblatex_str(&contents).unwrap()
        }
        Source::CslJson { path } => todo!(),
    };

    Ok(get_citations(
        (&library).into_iter(),
        &request.bibliography_config,
    ))
}

mod lua;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {}
}
