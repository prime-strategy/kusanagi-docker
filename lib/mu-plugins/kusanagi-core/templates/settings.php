<?php if ( ! defined( 'ABSPATH' ) ) exit; ?>
	<div class="wrap">
		<h2>KUSANAGI Settings</h2>

<ul class="tab-menu">
	<li<?php echo ! isset( $_GET['tab'] ) ? ' class="current"' : ' class="tab-item"'; ?>><a href="<?php echo esc_url( $this->home_url ); ?>">HOME</a></li>
<?php foreach ( $this->setting_tabs as $key => $tab ) :
	$link = add_query_arg( array( 'tab' => $key ), $this->home_url );
?>
	<li<?php echo isset( $_GET['tab'] ) && $key == $_GET['tab'] ? ' class="current"' : ' class="tab-item"'; ?>><a href="<?php echo esc_url( $link ); ?>"><?php echo esc_html( $tab ); ?></a></li>
<?php endforeach; ?>
</ul>

<?php if ( $this->messages ) : ?>
		<div id="message" class="updated">
			<?php foreach ( $this->messages as $message ) : ?>
			<p><?php echo $message; ?></p>
			<?php endforeach; ?>
		</div>
<?php endif; ?>
		<form action="" method="post">
			<?php wp_nonce_field( 'kusanagi-settings' ); ?>
<?php
if ( isset( $_GET['tab'] ) && file_exists( $this->templates_dir . '/tab-' . $_GET['tab'] . '.php' ) ) {
	$this->load_template( 'tab-' . $_GET['tab'] );
} else {
	$this->load_template( 'tab-home' );
}
if ( $this->form_submit ) {
	submit_button( false, 'primary', 'update-kusanagi-settings' );
}
?>
		</form>
	</div>
