"""Custom rules used in the ``snakemake`` pipeline.

This file is included by the pipeline ``Snakefile``.

"""


rule escape_summary:
    """Summarize escape across all sera alongside functional effects."""
    input:
        escape_csvs=expand(
            "results/antibody_escape/averages/{serum}_mut_effect.csv",
            serum=avg_assay_config["antibody_escape"],
        ),
        site_numbering_map_csv=config["site_numbering_map"],
        func_effects_csv="results/func_effects/averages/293T_entry_func_effects.csv",
        nb="notebooks/escape_summary.ipynb",
    output:
        chart="results/summaries/escape_summary_nolegend.html",
        csv="results/summaries/escape_summary.csv",
        nb="results/notebooks/escape_summary.ipynb",
    params:
        sera_yaml=lambda _, input: yaml.round_trip_dump(
            {
                "sera": dict(
                    zip(list(avg_assay_config["antibody_escape"]), input.escape_csvs)
                )
            }
        ),
    conda:
        os.path.join(config["pipeline_path"], "environment.yml"),
    log:
        "results/logs/escape_summary.txt",
    shell:
        """
        papermill {input.nb} {output.nb} \
            -p site_numbering_map_csv {input.site_numbering_map_csv} \
            -p func_effects_csv {input.func_effects_csv} \
            -p chart {output.chart} \
            -p csv_file {output.csv} \
            -y "{params.sera_yaml}" \
            &> {log}
        """


rule format_escape_summary_chart:
    """Format ``altair`` escape summary chart."""
    input:
        html=rules.escape_summary.output.chart,
        pyscript=os.path.join(config["pipeline_path"], "scripts/format_altair_html.py"),
    output:
        html="results/summaries/escape_summary.html",
        legend=temp("results/summaries/escape_summary.md"),
    params:
        title=(
            "Summary of serum escape and functional effects of mutations for the "
            "HA of A/turkey/Indiana/22-003707-003/2022 (H5N1)"
        ),
        legend=(
            "This is is an interactive chart. Mouseover points on the top line plots "
            "that summarize the per-site escape averaged across all sera and for "
            "individual sera. You can use the top zoom-bar or the line plots to zoom "
            "in on specific sites to show in the heatmaps that give per-mutation "
            "effects on serum escape or protein function. The options at the bottom "
            "let you only show escape for sites with some minimal functional effect "
            "(more deleterious mutations are grayed out in heatmap), choose the site "
            "summary metric, or floor the escape at zero."
        ),
        suffix=(
            f"Analysis by {config['authors']} ({config['year']}).\n\n See "
            f"[{config['github_repo_url']}]({config['github_repo_url']}) for code/data."
        ),
    conda:
        os.path.join(config["pipeline_path"], "environment.yml")
    log:
        "results/logs/format_escape_summary_chart.txt",
    shell:
        """
        echo "## {params.title}\n" > {output.legend}
        echo "{params.legend}\n\n" >> {output.legend}
        echo "{params.suffix}" >> {output.legend}
        python {input.pyscript} \
            --chart {input.html} \
            --markdown {output.legend} \
            --title "{params.title}" \
            --output {output.html}
        """


docs["Escape and functional effects summary"] = {
    "Notebook summarizing escape and functional effects": rules.escape_summary.output.nb,
    "Chart summarizing escape and functional effects": rules.format_escape_summary_chart.output.html,
    "CSV summarizing escape and functional effects": rules.escape_summary.output.csv,
}

docs["Site numbering"] = {
    "Reference to sequential site-numbering map": config["site_numbering_map"],
}

