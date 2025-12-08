<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * WordPress 自動アップデートモジュール
 */
class KUSANAGI_Security {

	private $option_key          = 'kusanagi-security-settings';
	private $defaults            = array();
	private $keys                = array();
	public $settings             = array();
	public $ms_settings          = array();


	/**
	 * Construct the KUSANAGI_Security.
	 */
	public function __construct() {
		$this->defaults = array(
			'disable_xmlrpc'    => '1',
			'disable_api_users' => '1',
		);
		$this->keys     = array_keys( $this->defaults );

		if ( is_multisite() ) {
			$ms_settings = get_site_option( $this->option_key );
			if ( false === $ms_settings ) {
				switch_to_blog( get_main_site_id() );
				$this->ms_settings = wp_parse_args( get_option( $this->option_key, array() ), $this->defaults );
				restore_current_blog();
			} else {
				$this->ms_settings = wp_parse_args( $ms_settings, $this->defaults );
			}
		}
		$this->settings = wp_parse_args( get_option( $this->option_key, array() ), $this->defaults );

		add_action( 'admin_init', array( $this, 'add_tab' ) );
		add_action( 'init', array( $this, 'disable_xmlrpc' ) );
		add_filter( 'rest_endpoints', array( $this, 'disable_api_users' ) );
	}


	/**
	 * Add security tab.
	 */
	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'security', __( 'Security', 'wp-kusanagi' ) );
	}

	/**
	 * Save the security settings.
	 *
	 * @return [type] [description]
	 */
	public function save_options() {
		global $WP_KUSANAGI;

		// phpcs:ignore WordPress.Security.NonceVerification.Missing
		$post_data = wp_unslash( $_POST );
		foreach ( $this->defaults as $key => $status ) {
			if ( isset( $post_data[ $key ] ) && in_array( $post_data[ $key ], array( '0', '1' ) ) ) {
				$status = sanitize_text_field( $post_data[ $key ] );
			}
			if ( is_multisite() && is_network_admin() ) {
				$this->ms_settings[ $key ] = $status;
			} else {
				$this->settings[ $key ] = $status;
			}
		}
		if ( is_multisite() && is_network_admin() ) {
			$ret = update_site_option( $this->option_key, $this->ms_settings );
		} else {
			$ret = update_option( $this->option_key, $this->settings );
		}

		if ( $ret ) {
			$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
		}
	}


	public function disable_xmlrpc() {
		if ( is_multisite() ) {
			$disabled = $this->ms_settings['disable_xmlrpc'] || $this->settings['disable_xmlrpc'];
		} else {
			$disabled = $this->settings['disable_xmlrpc'];
		}
		if ( $disabled ) {
			add_filter( 'xmlrpc_enabled', '__return_false' );
			remove_action( 'wp_head', 'rsd_link' );
			if ( defined( 'XMLRPC_REQUEST' ) && XMLRPC_REQUEST ) {
				header( 'HTTP/1.1 403 Forbidden' );
				exit;
			}
		}
	}


	public function disable_api_users( $endpoints ) {
		if ( preg_match( '/wp-admin\/.+/', wp_get_referer() ) ) {
			$disabled = false;
		} else if ( is_multisite() ) {
			$disabled = $this->ms_settings['disable_api_users'] || $this->settings['disable_api_users'];
		} else {
			$disabled = $this->settings['disable_api_users'];
		}
		if ( $disabled ) {
			if ( isset( $endpoints['/wp/v2/users'] ) ) {
				unset( $endpoints['/wp/v2/users'] );
			}
			if ( isset( $endpoints['/wp/v2/users/(?P[\d]+)'] ) ) {
				unset( $endpoints['/wp/v2/users/(?P[\d]+)'] );
			}
		}
		return $endpoints;
	}
} // class end.
$this->modules['security'] = new KUSANAGI_Security();
