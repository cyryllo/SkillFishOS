<?php
// SkillFishOS — visit collector. Called by a tiny beacon on every page.
// Records an anonymous, cookieless hit and returns 204 No Content.
require __DIR__ . '/_sfstats.php';

header('Content-Type: text/plain');
header('Cache-Control: no-store');
// CORS: only our own origins may post here.
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (preg_match('#^https?://([a-z0-9-]+\.)?skillfishos\.com$#i', $origin)) {
    header('Access-Control-Allow-Origin: ' . $origin);
}

$ua   = substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 300);
$path = substr((string)($_POST['p'] ?? $_GET['p'] ?? '/'), 0, 300);
$ref  = substr((string)($_POST['r'] ?? $_GET['r'] ?? ''), 0, 300);

// Keep only the path part of whatever was sent; drop query strings.
$path = parse_url($path, PHP_URL_PATH) ?: '/';
// Referrer: store host only (privacy + tidy aggregation), and ignore self-refs.
$ref_host = '';
if ($ref) {
    $h = parse_url($ref, PHP_URL_HOST) ?: '';
    if ($h && !preg_match('/skillfishos\.com$/i', $h)) $ref_host = strtolower($h);
}

try {
    $db = sfstats_db();
    $st = $db->prepare('INSERT INTO hits(ts,day,path,ref,vis,bot,browser,os)
                        VALUES(:ts,:day,:path,:ref,:vis,:bot,:br,:os)');
    $st->execute(array(
        ':ts'   => time(),
        ':day'  => gmdate('Y-m-d'),
        ':path' => $path,
        ':ref'  => $ref_host,
        ':vis'  => sfstats_visitor($ua),
        ':bot'  => sfstats_is_bot($ua),
        ':br'   => sfstats_browser($ua),
        ':os'   => sfstats_os($ua),
    ));
} catch (Throwable $e) {
    // never break a page load because of analytics
}

http_response_code(204);
