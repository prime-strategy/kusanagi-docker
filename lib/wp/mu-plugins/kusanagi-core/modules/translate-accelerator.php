<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Translate_Accelerator {

	public  $settings;
	private $default;
	private $file_cache_dir;

	public function __construct() {
		$this->settings = get_option( 'kusanagi-translate-accelerator-settings', array() );
		if ( defined( 'WP_INSTALLING' ) && WP_INSTALLING && ! is_array( $this->settings ) ) { return; }
		$this->default = array(
			'activate'       => 1,
			'cache_type'     => 'file',
			'frontend'       => 'cache',
			'wp-login'       => 'cache',
			'admin'          => 'cache',
			'file_cache_dir' => '',
			'error_mes'      => false,
		);
		

		$this->settings = array_merge( $this->default, $this->settings );
	
		if ( $this->settings['activate'] == true ) {
			$this->check();
		}

		add_action( 'admin_init'               , array( $this, 'add_tab' ) );
		add_action( 'upgrader_process_complete', array( $this, 'delete_cache' ) );
		add_action( 'wp_upgrade'               , array( $this, 'delete_cache' ) );
	}


	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'translate-accelerator', __( 'Translate Accelerator', 'wp-kusanagi' ) );
	}


	private function check() {
		$s =& $this->settings;
	
		if ( $s['cache_type'] == 'apc' ) {
			if ( ! function_exists( 'apc_store' ) ) {
				$this->error_mes( 'apc is not enable.' );
				return false;
			}
		}
	
		if ( $s['cache_type'] == 'file' ) {
			if ( $s['file_cache_dir'] == '' ) {
				$dir = WP_CONTENT_DIR . '/translate-accelerator';
				if ( ! file_exists( $dir ) ) {
					@mkdir( $dir );
				}
			} else {
				$dir = $s['file_cache_dir'];
			}
			if ( ! file_exists( $dir ) || ! is_dir( $dir ) ) {
				$this->error_mes( 'file_cahce_dir is not exists.' );
				return false;
			}
			if ( ! is_writable( $dir ) ) {
				$this->error_mes( 'file_cache_dir is not writable.' );
				return false;
			}
			$this->file_cache_dir = $dir;
		}
	
		add_filter( 'override_load_textdomain', array( $this, 'load_textdomain' ), 10, 3 );
	}



	private function error_mes( $mes ) {
		$s =& $this->settings;
		if ( is_admin() && $s['error_mes'] == true ) {
			echo $mes . '<br />';
		}
	}


	public function load_textdomain( $dum, $domain, $mofile ) {
		$s =& $this->settings;

		$segment = 'frontend';
		if ( is_admin() ) {
			$segment = 'admin';
		} elseif ( preg_match( '/wp-(login|signup|register)\.php/', $_SERVER['REQUEST_URI'] ) ) {
			$segment = 'wp-login';
		}
	
		if ( $s[$segment] == 'cutoff' ) {
			return true;
		} elseif ($s[$segment] == 'cache' ) {
			if ( false !== $this->cache_control( $domain, $mofile ) ) {
				return true;
			}
		}
		return false;
	}


	private function cache_control( $domain, $mofile ) {
		global $l10n;
		$s =& $this->settings;
		do_action( 'load_textdomain', $domain, $mofile );
		$mofile = apply_filters( 'load_textdomain_mofile', $mofile, $domain );
		if ( ! is_readable( $mofile ) ) return false;
		$mo = new MO();
	
		$cache = false;
	
		if ( $s['cache_type'] == 'apc' ) {
			$cache = apc_fetch( $mofile, $ret );
		} elseif ( $s['cache_type'] == 'file' ) {
			$file = preg_replace( '/^.*?wp-content/', '', $mofile );
			$file = preg_replace( '/\\\\|\//', '_', $file);
			$file = $this->file_cache_dir . '/' . $file;
			if ( file_exists( $file ) ) {
				$cache = file_get_contents( $file );
				$cache = unserialize( $cache );
			}
		}
	
		if ( is_object( $cache ) ) {
			$mo = $cache;
		} else {
			if ( ! $mo->import_from_file( $mofile ) ) {
				return false;
			}
			$mo->_gettext_select_plural_form = null;
	
			if ($s['cache_type'] == 'apc') {
				apc_store($mofile, $mo);
			} elseif ($s['cache_type'] == 'file') {
				$cache = serialize($mo);
				file_put_contents( $file, $cache );
			}
		}
	
		if ( isset( $l10n[$domain] ) ) {
			$mo->merge_with( $l10n[$domain] );
		}
		$l10n[$domain] = &$mo;
	}


	public function save_options() {
		global $WP_KUSANAGI;

		if ( isset( $_POST['cache_force_delete'] ) ) {
			$this->delete_cache();
		}
		$post_data = wp_unslash( $_POST );
		$settings = array();
		foreach ( $this->default as $key => $def ) {
			if ( $key == 'activate' && ! isset( $post_data['activate'] ) ) {
				$post_data['activate'] = false;
			}
			if ( $key != 'error_mes' ) {
				$settings[$key] = $post_data[$key];
			}
		}
		$this->settings = $settings;
		$ret = update_option( 'kusanagi-translate-accelerator-settings', $settings );
		if ( $ret ) {
			$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
		}
	}


	public function delete_cache() {
		switch ( $this->settings['cache_type'] ) {
		case 'apc' :
			if ( function_exists( 'apc_clear_cache' ) ) {
				apc_clear_cache( 'user' );
			}
			break;
		case 'file' :
			$this->file_cache_dir;
			if ( $dh = opendir( $this->file_cache_dir ) ) {
				while ( ( $file = readdir( $dh ) ) !== false ) {
					if ( is_file( $this->file_cache_dir . '/' . $file ) ) {
						@unlink( $this->file_cache_dir . '/' . $file );
					}
				}
			}
		}
	}
} // class end

$this->modules['translate-accelerator'] = new KUSANAGI_Translate_Accelerator;
