<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class WP_KUSANAGI {
	public  $version;
	private $modules_dir;
	private $templates_dir;
	public  $modules = array();
	private $setting_tabs = array();
	public  $messages = array();
	public  $error_messages = array();
	private $form_submit = true;
	public  $home_url;
	public  $menu_slug;
	public  $module_files = array();

	public function __construct( $file ) {
		$plugin_data = get_file_data( $file, array( 'version' => 'Version' ) );
		$this->version = $plugin_data['version'];
		$this->modules_dir   = __DIR__ . '/modules';
		$this->templates_dir = __DIR__ . '/templates';
		$files = array(
			'page-cache.php',
			'theme-switcher.php',
			'translate-accelerator.php',
			'performance-viewer.php',
			'image-optimizer.php',
			'replacer.php',
			'automatic-updates.php',
			'security-checker.php',
			'cache-clear.php',
		);

		foreach ( $files as $file ) {
			$this->module_files[] = $this->modules_dir . '/' . $file;
		}

		add_action( 'admin_menu'                   , array( $this, 'add_menu' ) );
		add_action( 'plugins_loaded'               , array( $this, 'load_textdomain' ) );
		add_filter( 'http_request_host_is_external', array( $this, 'allow_internal_request' ), 10, 2 );

		$this->load_modules();
	}

	public function add_menu() {
		$this->menu_slug = add_menu_page( 'KUSANAGI', 'KUSANAGI', 'manage_options', plugin_basename( __FILE__ ), array( $this, 'admin_page' ), false, 99 );
		add_action( 'load-' . $this->menu_slug, array( $this, 'update_settings' ) );
		add_action( 'load-' . $this->menu_slug, array( $this, 'register_enqueue' ) );
		$this->home_url = add_query_arg( array( 'page' => plugin_basename( __FILE__ ) ), admin_url( 'admin.php' ) );
	}

	public function load_textdomain() {
		load_textdomain( 'wp-kusanagi', dirname( __FILE__ ) . '/languages/wp-kusanagi-' . get_locale() . '.mo');
	}

	private function load_modules() {

		if ( defined( 'WP_INSTALLING' ) && WP_INSTALLING ) {
			$active_plugins = array();
		} else {
			if ( is_multisite() ) {
				$active_network_plugins = get_site_option( 'active_sitewide_plugins', array() );
			} else {
				$active_network_plugins = array();
			}
			$active_plugins = get_option( 'active_plugins', array() );
			$active_plugins = array_map( 'basename', array_merge( $active_network_plugins, $active_plugins ) );
			$active_plugins = array_unique( $active_plugins );
		}

		foreach ( $this->module_files as $module ) {
			$base_module = basename( $module );
			if ( 'translate-accelerator.php' == basename( $module ) ) {
				if ( in_array( '001-prime-strategy-translate-accelerator.php', $active_plugins ) ) { continue; }
			} elseif ( in_array( basename( $module ), array( 'page-cache.php', 'theme_switcher.php' ) ) ) {
				if ( in_array( 'wp-sitemanager.php', $active_plugins ) ) {
					if ( defined( 'WPSM_DISABLE_DEVICE' ) && WPSM_DISABLE_DEVICE &&
						 defined ( 'WPSM_DISABLE_CACHE' ) && WPSM_DISABLE_CACHE ) {
					} else {
						continue;
					}
				}
			}
			include_once( $module );
		}
	}

	public function add_tab( $slug, $title ) {
		if ( ! isset( $this->setting_tabs[$slug] ) ) {
			$this->setting_tabs[$slug] = $title;
			return true;
		}
		return false;
	}

	public function register_enqueue() {
		add_action( 'admin_enqueue_scripts', array( $this, 'enqueue' ) );
	}

	public function enqueue() {
		wp_enqueue_style( 'wp-kusanagi', plugin_dir_url( __FILE__ ) . 'css/kusanagi.css', array(), $this->version );
		wp_enqueue_script( 'wp-kusanagi', plugin_dir_url( __FILE__ ) . 'js/kusanagi.js', array( 'jquery' ), $this->version, true );
	}

	public function allow_internal_request( $return, $host ) {
		if ( preg_match( '/kusanagi\.tokyo$/', $host ) ) {
			$return = true;
		}
		return $return;
	}

	public function admin_page() {
		$this->load_template( 'settings' );
	}

	private function load_template( $file ) {
		if ( false !== strpos( $file, '../' ) ) { return; }
		if ( file_exists( $this->templates_dir . '/' . $file . '.php' ) ) {
			include( $this->templates_dir . '/' . $file . '.php' );
		}
	}

	public function update_settings() {
		if ( isset( $_POST['update-kusanagi-settings'] ) ) {
			check_admin_referer( 'kusanagi-settings' );
			if ( isset( $_GET['tab'] ) && isset( $this->modules[$_GET['tab']] ) && method_exists( $this->modules[$_GET['tab']], 'save_options' ) ) {
				$this->modules[$_GET['tab']]->save_options();
			}
		}
	}

} // class end.
