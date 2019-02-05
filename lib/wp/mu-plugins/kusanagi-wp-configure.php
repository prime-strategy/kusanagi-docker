<?php
/*
Plugin Name: KUSANAGI Configure
Plugin URI: http://kusanagi.tokyo/
Description: Set up WordPress settings for KUSANAGI
Version: 0.7
Author: Prime Strategy Co.,LTD.
Author URI: http://kusanagi.tokyo/
License: GPLv2 or later
*/

class KUSANAGI_WP_Configure {
	private $ini_file;

	public function __construct() {
		if ( defined( 'WP_SETUP_CONFIG' ) && WP_SETUP_CONFIG && ! defined( 'FS_METHOD' ) ) {
			define( 'FS_METHOD', 'direct' );
		}
		if ( defined( 'HHVM_VERSION' ) && defined( 'WP_DEBUG' ) && true == WP_DEBUG ) {
			set_error_handler( array( $this, 'hhvm_error_handler' ) );
		}

		if ( ! isset( $_SERVER['DOCUMENT_ROOT'] ) ) { return; }
		$this->ini_file = dirname( $_SERVER['DOCUMENT_ROOT'] ) . '/settings/kusanagi-default.ini';
		add_action( 'wp_install'   , array( $this, 'set_kusanagi_settings' ) );
		add_action( 'wpmu_new_blog', array( $this, 'ms_set_kusanagi_settings' ) );
	}


	public function set_kusanagi_settings() {
		if ( ! file_exists( $this->ini_file ) || ! is_readable( $this->ini_file ) ) { return; }
		$settings = parse_ini_file( $this->ini_file );
		foreach ( $settings as $option_name => $option_value ) {
			$option_value = maybe_unserialize( $option_value );
			if ( in_array( $option_name, array( 'active_plugins', 'stylesheet', 'template' ) ) ) {
				update_option( $option_name, $option_value );
			} else {
				add_option( $option_name, $option_value );
			}
		}
	}


	public function ms_set_kusanagi_settings( $blog_id ) {
		switch_to_blog( $blog_id );
		$this->set_kusanagi_settings();
		restore_current_blog();
	}

	public function hhvm_error_handler( $errno, $errstr, $errfile, $errline ) {
		switch ( $errno ) {
			case E_ERROR :
				$errlv = 'Error';
				break;
			case E_WARNING :
				$errlv = 'Warning';
				break;
			case E_NOTICE :
				$errlv = 'Notice';
				break;
			default :
				$errlv = 'Undefined';
		}
		echo "<b>$errlv</b> [$errno] $errstr in <b>$errfile</b> on line <b>$errline</b><br />\n";
	}

}

new KUSANAGI_WP_Configure;

