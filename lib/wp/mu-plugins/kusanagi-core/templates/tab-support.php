<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$this->form_submit = false;
$current_locale    = get_locale();
if ( function_exists( 'determine_locale' ) ) {
	$current_locale = determine_locale();
}
?>
<div class="wrap">
	<h3><?php esc_html_e( 'Documentation', 'wp-kusanagi' ); ?></h3>
	<p>
		<?php
		// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
		_e( 'Documentation: <a target="_blank" href="https://kusanagi.tokyo/en/document/">https://kusanagi.tokyo/en/document/</a>', 'wp-kusanagi' );
		?>
	</p>
	<p>
		<?php
		// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
		_e( 'Official FAQ: <a target="_blank" href="https://kusanagi.tokyo/en/faq/">https://kusanagi.tokyo/en/faq/</a>', 'wp-kusanagi' );
		?>
	</p>
</div>
<div class="wrap">
	<h3><?php esc_html_e( 'Community', 'wp-kusanagi' ); ?></h3>
	<p>
		<?php
		// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
		_e( 'The KUSANAGI User Forum is a free technical support and user community. (Japanese Only)<br>KUSANAGI User Forum: <a target="_blank" href="https://users.kusanagi.tokyo/">https://users.kusanagi.tokyo/</a>', 'wp-kusanagi' );
		?>
	</p>
</div>
<?php if ( 'ja' === $current_locale ) : ?>
<div class="wrap">
	<h3><?php esc_html_e( 'Mail Magazine', 'wp-kusanagi' ); ?></h3>
	<p>
		<?php
		// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
		_e( 'We publish two newsletters, “KUSANAGI Monthly” and “KUSANAGI Technology Monthly”.<br>Mail Magazine Subscription: <a target="_blank" href="https://www.prime-strategy.co.jp/mail-magazine/">https://www.prime-strategy.co.jp/mail-magazine/</a>', 'wp-kusanagi' );
		?>
	</p>
</div>
<?php endif; ?>
<div class="wrap">
	<h3><?php esc_html_e( 'SNS', 'wp-kusanagi' ); ?></h3>
	<p>
		<?php
		// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
		_e( 'Kusanagi Saya Official X: <a target="_blank" href="https://twitter.com/kusanagi_saya">https://twitter.com/kusanagi_saya</a>', 'wp-kusanagi' );
		?>
	</p>
	<?php if ( 'ja' === $current_locale ) : ?>
		<h4><?php esc_html_e( 'Developer SNS', 'wp-kusanagi' ); ?></h4>
		<p>
			<?php
			// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
			_e( 'Official Facebook: <a target="_blank" href="https://www.facebook.com/primestrategy/">https://www.facebook.com/primestrategy/</a>', 'wp-kusanagi' );
			?>
		</p>
		<p>
			<?php
			// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
			_e( 'Official X: <a target="_blank" href="https://twitter.com/primestrategyjp/">https://twitter.com/primestrategyjp/</a>', 'wp-kusanagi' );
			?>
		</p>
		<p>
			<?php
			// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
			_e( 'Official Instagram: <a target="_blank" href="https://www.instagram.com/primestrategy/">https://www.instagram.com/primestrategy/</a>', 'wp-kusanagi' );
			?>
		</p>
	<?php endif; ?>
</div>
<?php if ( 'ja' === $current_locale ) : ?>
<div class="wrap">
	<h3><?php esc_html_e( 'Paid Support', 'wp-kusanagi' ); ?></h3>
	<p>
		<?php
		// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
		_e( 'KUSANAGI Managed Services: <a target="_blank" href="https://www.prime-strategy.co.jp/services/kusanagi-managed-service/">https://www.prime-strategy.co.jp/services/kusanagi-managed-service/</a><br>Paid support by KUSANAGI developer.', 'wp-kusanagi' );
		?>
	</p>
</div>
<?php endif; ?>
<div class="wrap">
	<h3><?php esc_html_e( 'KUSANAGI Editions', 'wp-kusanagi' ); ?></h3>
	<p>
		<?php
		// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
		_e( 'KUSANAGI has a Business Edition for business use and a Premium Edition for even higher speed.<br>In addition to using the higher editions directly in the provided cloud, you can upgrade to these higher editions.<br><a target="_blank" href="https://kusanagi.tokyo/en/edition_and_upgrade/">https://kusanagi.tokyo/en/edition_and_upgrade/</a>', 'wp-kusanagi' );
		?>
	</p>
</div>