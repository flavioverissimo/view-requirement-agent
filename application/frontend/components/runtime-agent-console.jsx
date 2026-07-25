"use client";

import { useState } from "react";
import ReactMarkdown from "react-markdown";

import { formatRuntimeResultMarkdown } from "../lib/format-markdown";
import { requestRequirementInterpretation } from "../lib/requirement-api";

function downloadMarkdown(filename, content) {
  const blob = new Blob([content], { type: "text/markdown;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

function formatStatusLabel(status) {
  if (!status) {
    return "unknown";
  }

  return status.replace(/_/g, " ");
}

function toDownloadFileName(viewName) {
  const sanitizedViewName = viewName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  return `${sanitizedViewName || "requirement"}-result.md`;
}

export function RuntimeAgentConsole({ views }) {
  const [selectedViewName, setSelectedViewName] = useState(
    views[0]?.name ?? ""
  );
  const [criterion, setCriterion] = useState("");
  const [result, setResult] = useState(null);
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const selectedView =
    views.find((view) => view.name === selectedViewName) ?? null;

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");
    setResult(null);

    if (!selectedViewName || !criterion.trim()) {
      setError("Select a view and write a criterion before submitting.");
      return;
    }

    setIsSubmitting(true);

    try {
      const payload = await requestRequirementInterpretation({
        viewName: selectedViewName,
        criterion: criterion.trim(),
      });

      if (!payload?.result || typeof payload.result !== "object") {
        throw new Error("The API response did not include a valid result.");
      }

      setResult({
        response: payload.result,
        markdown: formatRuntimeResultMarkdown({
          response: payload.result,
          resolvedView: selectedView,
        }),
        downloadFileName: toDownloadFileName(selectedViewName),
      });
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Failed to process the request."
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="mx-auto max-w-7xl px-6 py-10 lg:px-10">
      <div className="mb-10 flex flex-col gap-4">
        <span className="w-fit rounded-full border border-ember/20 bg-white/80 px-4 py-1 text-xs uppercase tracking-[0.3em] text-ember">
          FastAPI Console
        </span>
        <h1 className="max-w-4xl font-display text-4xl leading-tight text-ink md:text-6xl">
          Requirement interpretation console
        </h1>
        <p className="max-w-3xl text-lg leading-8 text-slate">
          Select a view, send a natural-language criterion to the backend API,
          and review the structured response as Markdown.
        </p>
      </div>

      <form
        onSubmit={handleSubmit}
        className="grid gap-6 lg:grid-cols-[1.05fr_1.4fr]"
      >
        <section className="rounded-[2rem] border border-white/70 bg-white/80 p-6 shadow-panel backdrop-blur">
          <div className="mb-5 flex items-center justify-between gap-4">
            <div>
              <p className="text-sm uppercase tracking-[0.25em] text-moss">
                Column 1
              </p>
              <h2 className="mt-2 font-display text-2xl text-ink">
                Available Views
              </h2>
            </div>
            <div className="rounded-full bg-mist px-3 py-1 text-sm text-moss">
              {views.length} options
            </div>
          </div>

          <div className="space-y-3">
            {views.map((view) => {
              const isSelected = view.name === selectedViewName;

              return (
                <label
                  key={view.key}
                  className={`block cursor-pointer rounded-3xl border p-4 transition ${
                    isSelected
                      ? "border-ember bg-ember/10"
                      : "border-ink/10 bg-white/70 hover:border-moss/40 hover:bg-white"
                  }`}
                >
                  <input
                    type="radio"
                    name="view"
                    value={view.name}
                    checked={isSelected}
                    onChange={() => setSelectedViewName(view.name)}
                    className="sr-only"
                  />

                  <div className="flex items-start justify-between gap-4">
                    <div className="space-y-2">
                      <p className="font-display text-xl text-ink">{view.name}</p>
                      <p className="text-sm text-slate">
                        Configured URI:{" "}
                        <span className="font-medium text-ink">{view.uri}</span>
                      </p>
                      <p className="text-sm text-slate">
                        Configured type:{" "}
                        <span className="font-medium text-ink">{view.type}</span>
                      </p>
                    </div>

                    <div
                      className={`mt-1 h-4 w-4 rounded-full border ${
                        isSelected
                          ? "border-ember bg-ember"
                          : "border-ink/20 bg-transparent"
                      }`}
                    />
                  </div>
                </label>
              );
            })}
          </div>
        </section>

        <section className="rounded-[2rem] border border-white/70 bg-white/80 p-6 shadow-panel backdrop-blur">
          <div className="mb-5">
            <p className="text-sm uppercase tracking-[0.25em] text-moss">
              Column 2
            </p>
            <h2 className="mt-2 font-display text-2xl text-ink">
              Natural Language Criterion
            </h2>
          </div>

          <div className="mb-4 rounded-3xl border border-moss/15 bg-mist/40 p-4">
            <p className="text-sm text-slate">
              The selected view is sent to the FastAPI backend as `view_name`.
            </p>

            {selectedView ? (
              <div className="mt-3 grid gap-2 text-sm text-ink md:grid-cols-3">
                <p>
                  <span className="font-semibold">View:</span> {selectedView.name}
                </p>
                <p>
                  <span className="font-semibold">URI:</span> {selectedView.uri}
                </p>
                <p>
                  <span className="font-semibold">Type:</span> {selectedView.type}
                </p>
              </div>
            ) : null}
          </div>

          <textarea
            value={criterion}
            onChange={(event) => setCriterion(event.target.value)}
            placeholder="Ex: At least 90% of musical artists must have a homepage."
            className="min-h-[240px] w-full resize-y rounded-[1.75rem] border border-ink/10 bg-white px-5 py-4 text-base leading-7 text-ink outline-none transition placeholder:text-slate/60 focus:border-ember focus:ring-4 focus:ring-ember/10"
          />

          <div className="mt-5 flex flex-wrap items-center gap-3">
            <button
              type="submit"
              disabled={isSubmitting}
              className="rounded-full bg-ink px-6 py-3 text-sm font-semibold uppercase tracking-[0.25em] text-paper transition hover:bg-ember disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isSubmitting ? "Calling API..." : "Send to API"}
            </button>
          </div>

          {error ? (
            <div className="mt-5 rounded-3xl border border-ember/30 bg-ember/10 px-4 py-3 text-sm text-ember">
              {error}
            </div>
          ) : null}
        </section>
      </form>

      {result ? (
        <section className="mt-8 rounded-[2rem] border border-white/70 bg-white/90 p-6 shadow-panel backdrop-blur">
          <div className="mb-6 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-sm uppercase tracking-[0.25em] text-moss">
                Formatted Result
              </p>
              <h2 className="mt-2 font-display text-3xl text-ink">
                Markdown Ready to Read
              </h2>
            </div>

            <button
              type="button"
              onClick={() =>
                downloadMarkdown(
                  result.downloadFileName || "requirement-result.md",
                  result.markdown
                )
              }
              className="rounded-full border border-ink/10 bg-white px-5 py-3 text-sm font-semibold uppercase tracking-[0.22em] text-ink transition hover:border-moss/50 hover:text-moss"
            >
              Download .md
            </button>
          </div>

          <div className="grid gap-4 rounded-3xl border border-moss/10 bg-mist/35 p-4 text-sm text-ink md:grid-cols-3">
            <p>
              <span className="font-semibold">Status:</span>{" "}
              {formatStatusLabel(result.response?.status)}
            </p>
            <p>
              <span className="font-semibold">View:</span>{" "}
              {selectedView?.name || "not provided"}
            </p>
            <p>
              <span className="font-semibold">Type:</span>{" "}
              {selectedView?.type || "not provided"}
            </p>
          </div>

          <article className="markdown-output mt-6 rounded-[1.75rem] border border-ink/10 bg-white px-6 py-5">
            <ReactMarkdown>{result.markdown}</ReactMarkdown>
          </article>
        </section>
      ) : null}
    </div>
  );
}
