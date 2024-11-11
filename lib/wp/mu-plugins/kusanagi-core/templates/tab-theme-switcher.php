<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

?>
<h3><?php esc_html_e( 'Device Theme Switcher', 'wp-kusanagi' ); ?>
	<?php if ( isset( $_GET['action'] ) ) : ?>
	<a href="<?php echo esc_url( add_query_arg( array( 'tab' => 'theme-switcher' ), $this->home_url ) ); ?>" class="add-new-h2"><?php esc_html_e( 'Back', 'wp-kusanagi' ); ?></a>
	<?php endif; ?>
</h3>
<?php
$switch_action = isset( $_GET['action'] ) ? sanitize_text_field( $_GET['action'] ) : 'list';

switch ( $switch_action ) {
	case 'add_group':
	case 'edit_group':
		$group_id = isset( $_GET['group_id'] ) && $_GET['group_id'] ? sanitize_text_field( $_GET['group_id'] ) : 0;
		$this->load_template( 'theme-switcher-content-group' );
		break;
	case 'add_device':
	case 'edit_device':
		$this->load_template( 'theme-switcher-content-device' );
		break;
	case 'list':
	default:
		$this->load_template( 'theme-switcher-content-list' );
}
