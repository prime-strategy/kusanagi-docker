<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Replacer {
	
	private $replace_tpl;

	public function __construct() {
		$this->replace_tpl       = plugin_dir_path( dirname( __FILE__ ) ) . 'advanced_cache_tpl/replace-class.tpl';
		if ( is_admin() ) {
			add_action( 'admin_init'                           , array( $this, 'add_tab' ) );
		} else {

		}
	}

	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'replacer', __( 'Replacing', 'wp-kusanagi' ) );
	}


	public function save_options() {
		global $WP_KUSANAGI;

		$life_time = get_option( 'site_cache_life', array( 'home' => 60, 'archive' => 60, 'singular' => 360, 'exclude' => '', 'allowed_query_keys' => '', 'update' => 'none', 'replaces' => array(), 'replace_login' => 0 ) );

		if ( isset( $_POST['site_cache_life'] ) && is_array( $_POST['site_cache_life'] ) ) {
			$post_data = wp_unslash( $_POST );
			if ( is_array( $post_data['site_cache_life']['replaces'] ) ) {
				$replaces = array();
				foreach ( $post_data['site_cache_life']['replaces'] as $num => $values ) {
					$values = array_map( 'trim', $values );
					if ( $values['target'] && $values['replace'] ) {
						$replaces[] = $values;
					}
				}
				$minutes = $replaces;
			} else {
				$minutes = array();
			}
			$life_time['replaces'] = $minutes;
			$life_time['replace_login'] = (boolean)$post_data['site_cache_life']['replace_login'];
			
			$ret = update_option( 'site_cache_life', $life_time );
			if ( $ret ) {
				// replace class.phpの再生成
				$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
				$WP_KUSANAGI->modules['page-cache']->generate_replace_class_file();
			}
		}
	}
	
} // class end
$this->modules['replacer'] = new KUSANAGI_Replacer;
