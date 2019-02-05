<?php
if ( ! defined( 'ABSPATH' ) ) exit;

class KUSANAGI_Performance_viewer {

	private $default = array( 'enable' => 1, 'capability' => 'manage_options' );
	private $performance_threshold = array(
		'timer' => array( 0.5, 0.7 ),
		'query' => array( 50, 100 ),
	);

	public function __construct() {
		add_action( 'admin_bar_menu'       , array( $this, 'performance_information' ), 9999 );
		add_action( 'wp_enqueue_scripts'   , array( $this, 'enqueue' ) );
		add_action( 'admin_enqueue_scripts', array( $this, 'enqueue' ) );
		add_action( 'admin_init'           , array( $this, 'add_tab' ) );
		$this->settings = get_option( 'kusanagi-performance-viewer', $this->default );
	}


	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'performance-viewer', __( 'Performance Viewer', 'wp-kusanagi' ) );
	}


	public function enqueue() {
		global $WP_KUSANAGI;
		if ( is_admin_bar_showing() ) {
			wp_enqueue_style( 'kusanagi-admin-bar', plugin_dir_url( dirname( __FILE__ ) ) . 'css/kusanagi-admin-bar.css', array(), $WP_KUSANAGI->version );
		}
	}


	public function performance_information( $wp_admin_bar ) {
		if ( ! current_user_can( $this->settings['capability'] ) || ! $this->settings['enable'] ) { return; }
		$timer = timer_stop();
		$queries = get_num_queries();

		if ( $timer > $this->performance_threshold['timer'][1] || $queries > $this->performance_threshold['query'][1] ) {
			$class = 'bad';
		} elseif ( $timer > $this->performance_threshold['timer'][0] || $queries > $this->performance_threshold['query'][0] ) {
			$class = 'attention';
		} else {
			$class = 'good';
		}

		$wp_admin_bar->add_menu(array(
			'id'     => 'wp-performances',
			'parent' => 'top-secondary',
			'meta'   => array( 'class' => $class ),
			'title'  => '<span class="ab-icon"></span><span class="ab-label">' . esc_html( $timer ) . ' sec. ' . esc_html( $queries ) . " queries.</span>\n",
			'href'   => false,
		));
	}


	public function save_options() {
		global $WP_KUSANAGI;
		
		if ( isset( $_POST['kusanagi-performance-viewer'] ) ) {
			$post_data = wp_unslash( $_POST );
			$caps = get_role( 'administrator' );
			$data = array();
			$data['enable'] = preg_match( '/^[0-1]{1}$/', $post_data['kusanagi-performance-viewer']['enable'] ) ? $post_data['kusanagi-performance-viewer']['enable'] : $this->settings['enable'];
			$data['capability'] = in_array( $post_data['kusanagi-performance-viewer']['capability'], $caps->capabilities ) ? $post_data['kusanagi-performance-viewer']['capability'] : $this->settings['capability'];
			$ret = update_option( 'kusanagi-performance-viewer', $data );
			if ( $ret ) {
				$WP_KUSANAGI->messages[] = __( 'Update settings successfully.', 'wp-kusanagi' );
				wp_cache_delete ( 'alloptions', 'options' );
				$this->settings = get_option( 'kusanagi-performance-viewer', $this->default );
			}
		}
		
	}
} // class end.
$this->modules['performance-viewer'] = new KUSANAGI_Performance_viewer;
