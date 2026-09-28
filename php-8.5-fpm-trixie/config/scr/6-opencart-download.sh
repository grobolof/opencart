#!/bin/bash
# Скачивает последний релиз OpenCart 4.x и кладёт каталог upload/ в public/.
# docker-compose.yml, makefile, .env и README остаются в корне репозитория.

if [[ -f "$OC_ROOT/index.php" && -f "$OC_ROOT/system/startup.php" ]]; then
  log success "OpenCart уже есть в $OC_ROOT — скачивать не нужно"
  return 0
fi

log info "Ищу последний релиз OpenCart 4.x…"

json="$(mktemp)"
tmp="$(mktemp -d)"
trap 'rm -rf "$json" "$tmp"' EXIT

if ! curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: opencart-docker" \
  "https://api.github.com/repos/opencart/opencart/releases?per_page=100" \
  -o "$json"; then
  log error "Не удалось получить список релизов OpenCart"
  exit 1
fi

mapfile -t release < <(php -r '
$rels = json_decode(file_get_contents($argv[1]), true);
if (!is_array($rels) || !isset($rels[0]) || !is_array($rels[0])) {
    fwrite(STDERR, "GitHub API не вернул список релизов\n");
    exit(1);
}
$best = null;
foreach ($rels as $rel) {
    if (!empty($rel["draft"]) || !empty($rel["prerelease"])) {
        continue;
    }
    $tag = $rel["tag_name"] ?? "";
    if (!preg_match("/^4\\.\\d+\\.\\d+\\.\\d+$/", $tag)) {
        continue;
    }
    if ($best === null || version_compare($tag, $best["tag_name"], ">")) {
        $best = $rel;
    }
}
if ($best === null) {
    fwrite(STDERR, "Не найден релиз OpenCart 4.x\n");
    exit(1);
}
foreach ($best["assets"] as $asset) {
    $name = $asset["name"] ?? "";
    if (substr($name, -4) === ".zip") {
        echo $asset["browser_download_url"], "\n";
        echo $best["tag_name"], "\n";
        exit(0);
    }
}
fwrite(STDERR, "У релиза нет zip-архива\n");
exit(1);
' "$json")

url="${release[0]:-}"
tag="${release[1]:-}"
if [[ -z "$url" || -z "$tag" ]]; then
  log error "Не удалось выбрать архив релиза OpenCart"
  exit 1
fi

log info "Скачиваю OpenCart $tag, это может занять несколько минут…"
if ! curl -fL --retry 3 -o "$tmp/opencart.zip" "$url"; then
  log error "Не удалось скачать $url"
  exit 1
fi

if ! unzip -q "$tmp/opencart.zip" -d "$tmp/src"; then
  log error "Архив OpenCart повреждён"
  exit 1
fi

index="$(find "$tmp/src" -type f -path '*/upload/index.php' -print -quit)"
if [[ -z "$index" ]]; then
  log error "В архиве нет upload/index.php"
  exit 1
fi

mkdir -p "$OC_ROOT"
cp -a "$(dirname "$index")/." "$OC_ROOT/"
log success "OpenCart $tag скачан в $OC_ROOT"
