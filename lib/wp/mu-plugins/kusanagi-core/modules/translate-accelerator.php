<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

class KUSANAGI_Translate_Accelerator {

	public $settings;
	private $default;
	private $file_cache_dir;
	private $apc_mode;

	public function __construct() {
		$this->settings = get_option( 'kusanagi-translate-accelerator-settings', array() );
		if ( defined( 'WP_INSTALLING' ) && WP_INSTALLING && ! is_array( $this->settings ) ) {
			return;
		}
		$this->default = array(
			'activate'       => '1',
			'cache_type'     => 'file',
			'frontend'       => 'cache',
			'wp-login'       => 'cache',
			'admin'          => 'cache',
			'file_cache_dir' => '',
			'error_mes'      => false,
		);
		if ( function_exists( 'apcu_store' ) ) {
			$this->apc_mode = 'apcu';
		} elseif ( function_exists( 'apc_store' ) ) {
			$this->apc_mode = 'apc';
		} else {
			$this->apc_mode = false;
		}

		$this->settings = array_merge( $this->default, $this->settings );

		if ( '1' === $this->settings['activate'] ) {
			$this->check();
		}

		add_action( 'admin_init', array( $this, 'add_tab' ) );
		add_action( 'upgrader_process_complete', array( $this, 'delete_cache' ) );
		add_action( 'wp_upgrade', array( $this, 'delete_cache' ) );
		add_action( 'admin_menu', array( $this, 'clear_cache_hook' ), 9999 );
	}


	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'translate-accelerator', __( 'Translate Accelerator', 'wp-kusanagi' ) );
	}


	private function check() {
		$s =& $this->settings;

		if ( 'apc' === $s['cache_type'] ) {
			if ( false === $this->apc_mode ) {
				$this->error_mes( 'apc is not enable.' );

				return false;
			}
		}

		if ( 'file' === $s['cache_type'] ) {
			if ( '' === $s['file_cache_dir'] ) {
				$dir = WP_CONTENT_DIR . '/translate-accelerator';
				if ( ! file_exists( $dir ) ) {
					@mkdir( $dir );
				}
			} else {
				$dir = $s['file_cache_dir'];
			}
			if ( ! file_exists( $dir ) || ! is_dir( $dir ) ) {
				$this->error_mes( 'file_cache_dir is not exists.' );

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
		if ( is_admin() && true === $s['error_mes'] ) {
			echo esc_html( $mes ) . '<br />';
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

		if ( 'cutoff' === $s[ $segment ] ) {
			return true;
		} elseif ( 'cache' === $s[ $segment ] ) {
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
		if ( ! is_readable( $mofile ) ) {
			return false;
		}
		$mo = new MO();

		$cache = false;

		if ( 'apc' === $s['cache_type'] ) {
			switch ( $this->apc_mode ) {
				case 'apcu':
					$cache = apcu_fetch( $mofile, $ret );
					break;
				case 'apc':
					$cache = apc_fetch( $mofile, $ret );
					break;
				default:
					$cache = false;
			}
		} elseif ( 'file' === $s['cache_type'] ) {
			$file = preg_replace( '/^.*?wp-content/', '', $mofile );
			$file = preg_replace( '/\\\\|\//', '_', $file );
			$file = $this->file_cache_dir . '/' . $file;
			if ( is_readable( $file ) ) {
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

			if ( 'apc' === $s['cache_type'] ) {
				switch ( $this->apc_mode ) {
					case 'apcu':
						apcu_store( $mofile, $mo );
						break;
					case 'apc':
						apc_store( $mofile, $mo );
						break;
					default:
				}
			} elseif ( 'file' === $s['cache_type'] ) {
				$cache = serialize( $mo );
				file_put_contents( $file, $cache );
			}
		}

		if ( isset( $l10n[ $domain ] ) ) {
			$mo->merge_with( $l10n[ $domain ] );
		}
		// phpcs:ignore WordPress.WP.GlobalVariablesOverride.Prohibited
		$l10n[ $domain ] = &$mo;
	}

	public function clear_cache_hook() {
		global $WP_KUSANAGI;
		add_action( 'load-' . $WP_KUSANAGI->menu_slug, array( $this, 'clear_cache_control' ) );
	}

	public function clear_cache_control() {
		if ( isset( $_GET['_translation_delete_cache_nonce'] ) && wp_verify_nonce( sanitize_text_field( wp_unslash( $_GET['_translation_delete_cache_nonce'] ) ), 'translate_accelerator_delete_cache_action' ) &&
			 isset( $_GET['cache_force_delete'] ) && '1' === sanitize_text_field( wp_unslash( $_GET['cache_force_delete'] ) )
		) {
			$this->delete_cache();
			$redirect = remove_query_arg( array( 'cache_force_delete', '_translation_delete_cache_nonce' ) );
			wp_redirect( $redirect );
			exit;
		}
	}

	public function save_options() {
		global $WP_KUSANAGI;

		// phpcs:ignore WordPress.Security.NonceVerification.Missing
		$post_data = wp_unslash( $_POST );
		$settings  = array();
		foreach ( $this->default as $key => $def ) {
			if ( 'activate' === $key && ! isset( $post_data['activate'] ) ) {
				$post_data['activate'] = false;
			}
			if ( 'error_mes' !== $key ) {
				$settings[ $key ] = $post_data[ $key ];
			}
		}
		$this->settings = $settings;
		$ret            = update_option( 'kusanagi-translate-accelerator-settings', $settings );
		if ( $ret ) {
			$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
		}
	}


	public function delete_cache() {
		switch ( $this->settings['cache_type'] ) {
			case 'apc':
				switch ( $this->apc_mode ) {
					case 'apcu':
						apcu_clear_cache();
						break;
					case 'apc':
						apc_clear_cache( 'user' );
						break;
					default:
				}
				break;
			case 'file':
				// phpcs:ignore Squiz.PHP.DisallowMultipleAssignments.FoundInControlStructure -- probably false positive
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

$this->modules['translate-accelerator'] = new KUSANAGI_Translate_Accelerator();
