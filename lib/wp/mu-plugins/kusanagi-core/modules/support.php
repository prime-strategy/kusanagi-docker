<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * KUSANAGI Support Information
 */
class KUSANAGI_Support {
	public function __construct() {
		add_action( 'admin_init', array( $this, 'add_tab' ) );
	}

	/**
	 * Add support tab
	 */
	public function add_tab() {
		global $WP_KUSANAGI;
		$WP_KUSANAGI->add_tab( 'support', __( 'Support', 'wp-kusanagi' ) );
	}
}
$this->modules['support'] = new KUSANAGI_Support();
