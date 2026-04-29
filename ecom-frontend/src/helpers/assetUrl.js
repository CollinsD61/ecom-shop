const buildVersion = process.env.REACT_APP_BUILD_ID;

export function assetUrl(path) {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;

  if (!buildVersion) {
    return normalizedPath;
  }

  const separator = normalizedPath.includes("?") ? "&" : "?";
  return `${normalizedPath}${separator}v=${buildVersion}`;
}
