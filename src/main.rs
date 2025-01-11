use log;
use std::path::PathBuf;

use serde_json;

use clap::{Args, Parser, Subcommand};
use clap_verbosity_flag::{InfoLevel, Verbosity};

use biblioteca as lib;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    #[command(flatten)]
    verbose: Verbosity<InfoLevel>,
}

#[derive(Debug, Args)]
struct SourceToJsonArgs {
    #[command(subcommand)]
    source: lib::Source,
}

#[derive(Subcommand)]
enum Commands {
    SourceToJson(SourceToJsonArgs),
    SourceToBibliography(lib::SourceBibliographyRequest),
}

fn main() {
    let cli = Cli::parse();

    env_logger::Builder::new()
        .filter_level(cli.verbose.log_level_filter())
        .init();

    match &cli.command {
        Commands::SourceToJson(SourceToJsonArgs { source }) => {
            let entries = lib::source_to_json(source).unwrap();
            let json = serde_json::to_string_pretty(&entries)
                .expect("Serialization to JSON must not fail");
            println!("{}", json);
        }
        Commands::SourceToBibliography(request) => {
            let bibliography = lib::source_to_bibliography(request).unwrap();
            let json = serde_json::to_string_pretty(&bibliography)
                .expect("Serialization to JSON must not fail");
            println!("{}", json);
        }
    }
}
