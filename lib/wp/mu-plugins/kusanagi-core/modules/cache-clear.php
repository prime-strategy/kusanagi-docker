<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Cache_Clear {

    const NONCE_ACTION      = 'kusanagi-cache-clear';
    const NONCE_NAME        = 'kusanagi-cache-clear';

    public $cache_key       = '';
    public $fcache_dir      = '/var/cache/nginx/wordpress';

    public function __construct() {
        add_action( 'admin_bar_menu'       , array( $this, 'add_cache_clear_button' ), 100 );
        add_action( 'wp_enqueue_scripts'   , array( $this, 'enqueue' ) );
        add_action( 'plugins_loaded'       , array( $this, 'exe_clear_cache' ) );
        if ( isset($_SERVER['REQUEST_URI']) && $_SERVER['REQUEST_URI'] ) {
            $this->cache_key = $_SERVER['REQUEST_URI'];
        }
    }

    public function enqueue() {
        global $WP_KUSANAGI;
        if ( is_admin_bar_showing() ) {
            wp_enqueue_style( 'kusanagi-admin-bar', plugin_dir_url( dirname( __FILE__ ) ) . 'css/kusanagi-admin-bar.css', array(), $WP_KUSANAGI->version );
        }
    }

    public function add_cache_clear_button( $wp_admin_bar ) {
        if ( is_admin() ) {
            return;
        }
        $wp_admin_bar->add_menu(array(
            'id'     => 'wp-cache-clear',
            'parent' => 'top-secondary',
            'meta'   => array( 'class' => 'cache-clear' ),
            'title'  => '<span class="ab-icon"></span><span class="ab-label">cache clear</span>',
            'href'   => wp_nonce_url( $this->cache_key, self::NONCE_ACTION, self::NONCE_NAME ),
        ));
    }

    private function current_user_can_clear_cache () {
        if ( ! is_user_logged_in() ) {
            return false;
        }
        if ( ! get_user_option( 'show_admin_bar_front', get_current_user_id() ) ) {
            return false;
        } else {
            return true;
        }
    }

    private function is_valid_access () {
        return isset( $_GET[self::NONCE_NAME] ) && wp_verify_nonce( $_GET[self::NONCE_NAME], self::NONCE_ACTION );
    }

    public function exe_clear_cache() {
        global $WP_KUSANAGI;

        if ( $this->current_user_can_clear_cache() ) {
            if ( $this->is_valid_access() ) {
                $uri = remove_query_arg( self::NONCE_NAME, $this->cache_key );
                $this->clear_fcache( $uri );
                $this->clear_bcache( $uri . '$' );
                wp_redirect( $uri, 302 );
                exit;
            }
        }
    }

    public function clear_bcache ( $key = '' ) {
        global $wpdb;
        $ret = $wpdb->get_results( 'show tables', ARRAY_N );
        foreach ($ret as $row) {
            $t = $row[0];
            if ( preg_match( '/site_cache$/', $t ) ) {
                if ( $key !== '' ) {
                    $hashes = $wpdb->get_results( $wpdb->prepare("SELECT hash, device_url FROM $t WHERE device_url RLIKE %s", $key ));
                    if ( $hashes ) {
                        foreach ( $hashes as $hash ) {
                            $wpdb->query( $wpdb->prepare("DELETE FROM $t WHERE hash = %s", $hash->hash ) );
                        }
                    }
                } else {
                    $wpdb->query( 'truncate table `' . $wpdb->escape( $t, 'recursive' ) . '`' );
                }
            }
        }
    }

    public function clear_fcache ( $key = '' ) {
        $files = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator( $this->fcache_dir, FilesystemIterator::CURRENT_AS_PATHNAME | FilesystemIterator::KEY_AS_PATHNAME | FilesystemIterator::SKIP_DOTS )
        );
        $quoted_home = preg_quote( get_option( 'home' ), '#' );
        foreach ($files as $file_path) {
            if ( $key ) {
                $html = file_get_contents($file_path);
                if ( preg_match( '#KEY\:.*' . $quoted_home  . '(.*)#', $html, $m ) ) {
                    if ( strcasecmp($m[1], $key ) === 0 ) {
                        unlink($file_path);
                    }
                }
            } else {
                unlink($file_path);
            }
        }
    }

} // class end.
$this->modules['cache_clear'] = new KUSANAGI_Cache_Clear;
