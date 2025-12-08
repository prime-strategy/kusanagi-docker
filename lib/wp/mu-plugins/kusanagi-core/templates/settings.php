<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
$current_tab = 'home';
if ( isset( $_GET['tab'] ) && ! empty( $_GET['tab'] ) && isset( $this->setting_tabs[ $_GET['tab'] ] ) ) {
	$current_tab = $_GET['tab'];
}
$current_tab = sanitize_text_field( $current_tab );
?>
<div class="wrap">
	<h2>KUSANAGI Settings</h2>

	<?php do_action( 'kusanagi_admin_notices' ); ?>

	<ul class="tab-menu">
		<li class="<?php echo $current_tab && 'home' === $current_tab ? 'current' : 'tab-item'; ?>">
			<a href="<?php echo esc_url( $this->home_url ); ?>">HOME</a>
		</li>
		<?php
		foreach ( $this->setting_tabs as $key => $name ) :
			$tab_link = add_query_arg( array( 'tab' => $key ), $this->home_url );
			?>
			<li class="<?php echo $current_tab && $key === $current_tab ? 'current' : 'tab-item'; ?>">
				<a href="<?php echo esc_url( $tab_link ); ?>"><?php echo esc_html( $name ); ?></a>
			</li>
		<?php endforeach; ?>
	</ul>

	<?php if ( $this->messages ) : ?>
		<div id="message" class="updated">
			<?php foreach ( $this->messages as $message ) : ?>
				<p>
					<?php echo esc_html( $message ); ?>
				</p>
			<?php endforeach; ?>
		</div>
	<?php endif; ?>
	<form action="" method="post">
	<?php
		wp_nonce_field( 'kusanagi-settings' );
		$this->load_template( 'tab-' . $current_tab );
		// phpcs:disable Generic.WhiteSpace.ScopeIndent.IncorrectExact -- tabs not recognized correctly.
		if ( $this->form_submit ) {
			submit_button( false, 'primary', 'update-kusanagi-settings' );
		}
	?>
	</form>
</div>
