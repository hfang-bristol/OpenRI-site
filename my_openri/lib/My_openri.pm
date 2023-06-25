package My_openri;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
	my $self = shift;
	
	$ENV{MOJO_REVERSE_PROXY} = 1;
	$self->config(
		hypnotoad => {
			listen  => ['http://*:3010'],
			workers => 8,
			keep_alive_timeout => 300,
			websocket_timeout => 600,
			proxy => 1
		}
	);
	
	# Documentation browser under "/perldoc"
  	$self->plugin('PODRenderer');
  	#$self->plugin('PODViewer');

  	# Router
  	my $r = $self->routes;
	
	# Template names are expected to follow the template.format.handler scheme, with template defaulting to controller/action or the route name, format defaulting to html and handler to ep
	
  	# Normal route to controller
  	## Home
  	$r->get('/')->to(template=>'index', controller=>'action', action=>'index');
  	
  	## OpenRI (and typos)
	$r->get('/OpenRI')->to(template=>'index', controller=>'action', action=>'index');
	$r->get('/openri')->to(template=>'index', controller=>'action', action=>'index');
	$r->get('/OPENRI')->to(template=>'index', controller=>'action', action=>'index');

  	## about
  	$r->get('/OpenRI/about')->to(template=>'OpenRI_about', format=>'html', handler=>'ep', controller=>'action', action=>'index_default');

	## manual (see Action.pm -> sub booklet -> redirect_to)
	## so that '/OpenRI/manual' equivalent to '/OpenRIbooklet/index.html' (located at my_openri/public/OpenRIbooklet/index.html)
  	$r->get('/OpenRI/manual')->to(controller=>'action', action=>'booklet');

  	### RI2Terms
	$r->get('/OpenRI/RI2Terms')->to(template=>'OpenRI_RI2Terms', format=>'html', handler=>'ep', controller=>'action', action=>'OpenRI_RI2Terms', post_flag=>0);
	$r->post('/OpenRI/RI2Terms')->to(template=>'OpenRI_RI2Terms', format=>'html', handler=>'ep', controller=>'action', action=>'OpenRI_RI2Terms', post_flag=>1);
	
  	### RI2Genes
	$r->get('/OpenRI/RI2Genes')->to(template=>'OpenRI_RI2Genes', format=>'html', handler=>'ep', controller=>'action', action=>'OpenRI_RI2Genes', post_flag=>0);
	$r->post('/OpenRI/RI2Genes')->to(template=>'OpenRI_RI2Genes', format=>'html', handler=>'ep', controller=>'action', action=>'OpenRI_RI2Genes', post_flag=>1);

  	#############################################
  	#Restrictive placeholders (http://mojolicious.org/perldoc/Mojolicious/Guides/Tutorial#Placeholders)
  	
  	if(1){
		# per gene
  		$r -> get('/OpenRI/gene/:gene' => [gene=>qr/\S+/]) -> to(template=>'OpenRI_gene', format=>'html', handler=>'ep', controller=>'action', action=>'OpenRI_gene');
  		
		# per cid
  		$r -> get('/OpenRI/:modal/:cid' => [modal=>['abc','pchic','qtl'],cid=>qr/\S+/]) -> to(template=>'OpenRI_modal_cid', format=>'html', handler=>'ep', controller=>'action', action=>'OpenRI_modal_cid');
  	
		# browser
  		$r -> get('/OpenRI/browser') -> to(template=>'OpenRI_browser', format=>'html', handler=>'ep', controller=>'action', action=>'OpenRI_browser');
  	
  	}
  	
}

1;

