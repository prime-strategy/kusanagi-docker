<?php if ( ! defined( 'ABSPATH' ) ) exit; ?>
<h3><?php _e( 'Device Theme Switcher', 'wp-kusanagi' ); ?><?php if ( isset( $_GET['action'] ) ) : ?> <a href="<?php echo esc_url( add_query_arg( array( 'tab' => 'theme-switcher' ), $this->home_url ) ); ?>" class="add-new-h2"><?php _e( 'Back', 'wp-kusanagi' ); ?></a><?php endif; ?></h3>
<?php
$action = isset( $_GET['action'] ) ? $_GET['action'] : 'list';

switch ( $action ) {
	case 'add_group' :
	case 'edit_group' :
		$group_id = isset( $_GET['group_id'] ) && $_GET['group_id'] ? $_GET['group_id'] : 0;
		$this->load_template( 'theme-switcher-content-group' );
		break;
	case 'add_device' :
	case 'edit_device' :
		$this->load_template( 'theme-switcher-content-device' );
		break;
	case 'list' :
	default :
		$this->load_template( 'theme-switcher-content-list' );
}
