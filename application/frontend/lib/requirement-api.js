const DEFAULT_API_BASE_URL = "http://localhost:8000/api/v1";

function trimTrailingSlash(value) {
  return value.replace(/\/+$/, "");
}

export function getRequirementApiBaseUrl() {
  const configuredBaseUrl =
    process.env.NEXT_PUBLIC_API_BASE_URL || DEFAULT_API_BASE_URL;

  return trimTrailingSlash(configuredBaseUrl);
}

export async function requestRequirementInterpretation({
  viewName,
  criterion,
}) {
  const headers = {
    "Content-Type": "application/json",
  };

  const response = await fetch(
    `${getRequirementApiBaseUrl()}/requirements/interpret`,
    {
      method: "POST",
      headers,
      body: JSON.stringify({
        view_name: viewName,
        criterion,
      }),
      cache: "no-store",
    }
  );

  const payload = await response.json().catch(() => null);

  if (!response.ok) {
    throw new Error(
      payload?.detail || payload?.error || "Failed to process the request."
    );
  }

  return payload;
}
