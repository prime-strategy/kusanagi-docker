/**
 * 開発者へ: WordPress デバッグモード
 *
 * この値を true にすると、開発中に注意 (notice) を表示します。
 * テーマおよびプラグインの開発者には、その開発環境においてこの WP_DEBUG を使用することを強く推奨します。
 */
define('WP_DEBUG', false);

#define('WP_ALLOW_MULTISITE', true);
#define('FORCE_SSL_ADMIN', true);
#define('WP_CACHE', true);

define('FS_METHOD', 'ftpsockets');
define('FTP_HOST', 'localhost');
define('FTP_USER', 'kusanagi');
#define('FTP_PASS', '*****');
