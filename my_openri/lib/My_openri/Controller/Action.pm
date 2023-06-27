package My_openri::Controller::Action;
use My_openri::Controller::Utils;
use Mojo::Base 'Mojolicious::Controller';
use JSON;
use LWP::Simple;
use List::Util qw( min max sum );
use POSIX qw(strftime);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

# Render template "OpenRI_about.html.ep"
sub index_default {
	my $c = shift;
  	$c->render();
}


sub booklet {
  	my $c = shift;
	$c->redirect_to("/OpenRIbooklet/index.html");
}


# Render template "index.html.ep"
sub index {
	my $c = shift;
	
	my $dbh = My_openri::Controller::Utils::DBConnect('OpenRIdb');
	my $sth;

	#############
	# json_gene
	#############
	$sth = $dbh->prepare('select Gene,Description from gene_info;');
	$sth->execute();
	if($sth->rows>0){
		my @data_gene;
		while (my @row = $sth->fetchrow_array) {
			
			my $rec;
			$rec->{Gene}=$row[0];
			$rec->{Description}=$row[1];
			push @data_gene,$rec;				
			
		}
		print STDERR scalar(@data_gene)."\n";
		$c->stash(json_gene => encode_json(\@data_gene));
	}
	$sth->finish();
	
	#############
	# json_abc
	#############
	$sth = $dbh->prepare('select Modal,Context,label,cid from context_info where Modal="ABC";');
	$sth->execute();
	if($sth->rows>0){
		my @data_abc;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{Modal}=$row[0];
			$rec->{Context}=$row[1];
			$rec->{label}=$row[2];
			$rec->{cid}=$row[3];
			
			push @data_abc,$rec;
			
		}
		print STDERR scalar(@data_abc)."\n";
		$c->stash(json_abc => encode_json(\@data_abc));
	}
	$sth->finish();
	
	#############
	# json_pchic
	#############
	$sth = $dbh->prepare('select Modal,Context,label,cid from context_info where Modal="PCHiC";');
	$sth->execute();
	if($sth->rows>0){
		my @data_pchic;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{Modal}=$row[0];
			$rec->{Context}=$row[1];
			$rec->{label}=$row[2];
			$rec->{cid}=$row[3];
			
			push @data_pchic,$rec;
			
		}
		print STDERR scalar(@data_pchic)."\n";
		$c->stash(json_pchic => encode_json(\@data_pchic));
	}
	$sth->finish();
	
	#############
	# json_qtl
	#############
	$sth = $dbh->prepare('select Modal,Context,label,cid from context_info where Modal="QTL";');
	$sth->execute();
	if($sth->rows>0){
		my @data_qtl;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{Modal}=$row[0];
			$rec->{Context}=$row[1];
			$rec->{label}=$row[2];
			$rec->{cid}=$row[3];
			
			push @data_qtl,$rec;
			
		}
		print STDERR scalar(@data_qtl)."\n";
		$c->stash(json_qtl => encode_json(\@data_qtl));
	}
	$sth->finish();
	
	################
	# realtime
	################
	my $datestring = strftime "%Y-%m-%d", localtime;
	$sth = $dbh->prepare('select Modal,CID,num_ri from context_info;');
	$sth->execute();
	my %modal;
	my $count_cid=0;
	my $count_ri=0;
	if($sth->rows>0){
		while (my @row = $sth->fetchrow_array) {
			$modal{$row[0]}=1;
			$count_cid++;
			$count_ri=$count_ri + $row[2];
		}
	}
	$sth->finish();
	my $realtime_data;
	$realtime_data->{Date}=$datestring;
	$realtime_data->{Modal}=scalar(keys %modal);
	$realtime_data->{CID}=$count_cid;
	$realtime_data->{RI}=$count_ri;
	$c->stash(realtime_data => $realtime_data);
	
	
	My_openri::Controller::Utils::DBDisconnect($dbh);
	
	#################################################################
	
  	$c->render();
}


# Render template "OpenRI_gene.html.ep"
sub OpenRI_gene {
	my $c = shift;

	my $gene= $c->param("gene") || "LOXL4";
	
	my $dbh = My_openri::Controller::Utils::DBConnect('OpenRIdb');
	my $sth;
	
	##############
	# http://127.0.0.1:3080/OpenRI/gene/LOXL4
	my $gene_data; # reference or ''
	my $json = ""; # json or ''
	##############

	if(1){
		#SELECT Gene,Description FROM gene_info WHERE Gene="CCDC127";
		$sth = $dbh->prepare( 'SELECT Gene,GeneID,GeneLoc,Description FROM gene_info WHERE Gene=?;' );
		$sth->execute($gene);
		$gene_data=$sth->fetchrow_hashref;
		if(!$gene_data->{Gene}){
			#return $c->reply->not_found;
			$gene_data="";
		}
		$sth->finish();
		
	}
	$c->stash(gene_data => $gene_data);
	
	################
	# ri (ABC)
	################
	#SELECT b.CID AS cid, b.Modal AS cmodal, b.Context AS ccontext, b.label AS clabel, a.GR AS gr, a.Score AS score FROM regulatory_interaction as a, context_info as b WHERE a.CID=b.CID AND b.Modal="ABC" AND a.Gene="CCDC127" ORDER BY a.CID ASC,a.Score DESC LIMIT 10;
	$sth = $dbh->prepare('SELECT b.CID AS cid, b.Modal AS cmodal, b.Context AS ccontext, b.label AS clabel, a.GR AS gr, a.Score AS score FROM regulatory_interaction as a, context_info as b WHERE a.CID=b.CID AND b.Modal="ABC" AND a.Gene=? ORDER BY a.CID ASC,a.Score DESC;');
	$sth->execute($gene);
	$json = "";
	if($sth->rows > 0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{gene}=$gene;
			$rec->{cid}="<a href='/OpenRI/abc/".$row[0]."' target='_blank'><i class='fa fa-copyright fa-1x'></i>&nbsp;&nbsp;".$row[0]."</a>";
			$rec->{cmodal}=$row[1];
			$rec->{ccontext}=$row[2];
			$rec->{clabel}=$row[3];
			$rec->{gr}=$row[4];
			$rec->{score}=$row[5];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno_abc => $json);
	
	################
	# ri (PCHiC)
	################
	#SELECT b.CID AS cid, b.Modal AS cmodal, b.Context AS ccontext, b.label AS clabel, a.GR AS gr, a.Score AS score FROM regulatory_interaction as a, context_info as b WHERE a.CID=b.CID AND b.Modal="PCHiC" AND a.Gene="LOXL4" ORDER BY a.CID ASC,a.Score DESC LIMIT 10;
	$sth = $dbh->prepare('SELECT b.CID AS cid, b.Modal AS cmodal, b.Context AS ccontext, b.label AS clabel, a.GR AS gr, a.Score AS score FROM regulatory_interaction as a, context_info as b WHERE a.CID=b.CID AND b.Modal="PCHiC" AND a.Gene=? ORDER BY a.CID ASC,a.Score DESC;');
	$sth->execute($gene);
	$json = "";
	if($sth->rows > 0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{gene}=$gene;
			$rec->{cid}="<a href='/OpenRI/pchic/".$row[0]."' target='_blank'><i class='fa fa-copyright fa-1x'></i>&nbsp;&nbsp;".$row[0]."</a>";
			$rec->{cmodal}=$row[1];
			$rec->{ccontext}=$row[2];
			$rec->{clabel}=$row[3];
			$rec->{gr}=$row[4];
			$rec->{score}=$row[5];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno_pchic => $json);
	
	
	################
	# ri (QTL)
	################
	#SELECT b.CID AS cid, b.Modal AS cmodal, b.Context AS ccontext, b.label AS clabel, a.GR AS gr, a.Score AS score FROM regulatory_interaction as a, context_info as b WHERE a.CID=b.CID AND b.Modal="QTL" AND a.Gene="LOXL4" ORDER BY a.CID ASC,a.Score DESC LIMIT 10;
	$sth = $dbh->prepare('SELECT b.CID AS cid, b.Modal AS cmodal, b.Context AS ccontext, b.label AS clabel, a.GR AS gr, a.Score AS score FROM regulatory_interaction as a, context_info as b WHERE a.CID=b.CID AND b.Modal="QTL" AND a.Gene=? ORDER BY a.CID ASC,a.Score DESC;');
	$sth->execute($gene);
	$json = "";
	if($sth->rows > 0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{gene}=$gene;
			$rec->{cid}="<a href='/OpenRI/qtl/".$row[0]."' target='_blank'><i class='fa fa-copyright fa-1x'></i>&nbsp;&nbsp;".$row[0]."</a>";
			$rec->{cmodal}=$row[1];
			$rec->{ccontext}=$row[2];
			$rec->{clabel}=$row[3];
			$rec->{gr}=$row[4];
			$rec->{score}=$row[5];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno_qtl => $json);

	My_openri::Controller::Utils::DBDisconnect($dbh);
	
	$c->render();
}


# Render template "OpenRI_modal_cid.html.ep"
sub OpenRI_modal_cid {
	my $c = shift;

	my $modal= $c->param("modal");
	my $cid= $c->param("cid") || "C00001";
	
	my $dbh = My_openri::Controller::Utils::DBConnect('OpenRIdb');
	my $sth;
	
	###############################################
	# http://127.0.0.1:3080/OpenRI/abc/C00001
	my $cid_data; # reference or ''
	my $json = ""; # json or ''
	##############
	
	## Modal Information
	my %MODAL_INFO = (
		"ABC" => 'Activity-by-contact (ABC)',
		"PCHiC" => 'Promoter Capture Hi-C (PCHiC)',
		"QTL" => 'Quantitative Trait Loci (QTL)',
	);
		
	###############################################
	# rec_anno
	##############
	#SELECT a.CID AS cid, a.GR AS gr, b.Gene AS gsymbol, b.GeneID AS ggid, b.Description AS gdes, a.Score AS score FROM regulatory_interaction as a, gene_info as b WHERE a.Gene=b.Gene AND a.CID="C00001" ORDER BY a.Score DESC,a.Gene LIMIT 10;
	$sth = $dbh->prepare('SELECT a.CID AS cid, a.GR AS gr, b.Gene AS gsymbol, b.GeneID AS ggid, b.Description AS gdes, a.Score AS score FROM regulatory_interaction as a, gene_info as b WHERE a.Gene=b.Gene AND a.CID=? ORDER BY a.Score DESC,a.Gene;');
	$sth->execute($cid);
	$json = "";
	my $count_ri=0;
	my %gene;
	my %gr;
	if($sth->rows > 0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
		
			if(1){
				my $rec;
				$rec->{cid}=$row[0];
				$rec->{gr}=$row[1];
				$rec->{gsymbol}="<a href='/OpenRI/gene/".$row[2]."' target='_blank'><i class='fa fa-glide fa-1x'></i>&nbsp;&nbsp;".$row[2]."</a>";
				$rec->{gid}=$row[3];
				$rec->{gdes}=$row[4];
				$rec->{score}=$row[5];
				push @data,$rec;
				
				# num of interactions
				#$count_ri++;
				# num of genes
				#$gene{$row[2]}=1;
				# num of GR
				#$gr{$row[1]}=1;
			}
			
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_anno => $json);
	
	###############################################
	# cid_data
	##############
	#SELECT CID,Modal,Context,num,num_gene,label,pmid FROM context_info WHERE CID="C0001" LIMIT 10;
	$sth = $dbh->prepare( 'SELECT CID,Modal,Context,num_ri,num_gene,label,pmid FROM context_info WHERE CID=?;' );
	$sth->execute($cid);
	if($sth->rows > 0){
		$cid_data=$sth->fetchrow_hashref;
		
		# Modal_info
		$cid_data->{Modal_info}=$MODAL_INFO{$cid_data->{Modal}};
		
		if(0){
		# PMID
		$cid_data->{PMID}='';
		if($cid_data->{Modal} eq "ABC"){
			$cid_data->{PMID}=33828297;
			
		}elsif($cid_data->{Modal} eq "PCHiC"){
			if($cid_data->{label}=~/PMID(\d+)/){
				$cid_data->{PMID}=$1;
			}
			
		}elsif($cid_data->{Modal} eq "QTL"){
			if($cid_data->{label}=~/Alasoo_2018_/){
				$cid_data->{PMID}=29379200;
			}
			if($cid_data->{label}=~/BLUEPRINT_/){
				$cid_data->{PMID}=27863251;
			}
			if($cid_data->{label}=~/BrainSeq_brain/){
				$cid_data->{PMID}=30050107;
			}
			if($cid_data->{label}=~/CEDAR_microarray_/){
				$cid_data->{PMID}=29930244;
			}
			if($cid_data->{label}=~/eQTLGen/){
				$cid_data->{PMID}=34475573;
			}
			if($cid_data->{label}=~/Fairfax_2012_/){
				$cid_data->{PMID}=22446964;
			}
			if($cid_data->{label}=~/Fairfax_2014_/){
				$cid_data->{PMID}=24604202;
			}
			if($cid_data->{label}=~/FUSION_/){
				$cid_data->{PMID}=31076557;
			}
			if($cid_data->{label}=~/GENCORD_/){
				$cid_data->{PMID}=23755361;
			}
			if($cid_data->{label}=~/GEUVADIS_/){
				$cid_data->{PMID}=24037378;
			}
			if($cid_data->{label}=~/GTEx_V8_/){
				$cid_data->{PMID}=32913098;
			}
			if($cid_data->{label}=~/HipSci_/){
				$cid_data->{PMID}=28489815;
			}
			if($cid_data->{label}=~/Kasela_2017_/){
				$cid_data->{PMID}=28248954;
			}
			if($cid_data->{label}=~/Naranbhai_2015_/){
				$cid_data->{PMID}=26151758;
			}
			if($cid_data->{label}=~/Nedelec_2016_/){
				$cid_data->{PMID}=27768889;
			}
			if($cid_data->{label}=~/Plasma/){
				$cid_data->{PMID}=29875488;
			}
			if($cid_data->{label}=~/Quach_2016_/){
				$cid_data->{PMID}=27768888;
			}
			if($cid_data->{label}=~/ROSMAP_/){
				$cid_data->{PMID}=28869584;
			}
			if($cid_data->{label}=~/Schmiedel_2018_/){
				$cid_data->{PMID}=30449622;
			}
			if($cid_data->{label}=~/Schwartzentruber_2018_/){
				$cid_data->{PMID}=29229984;
			}
			if($cid_data->{label}=~/TwinsUK_/){
				$cid_data->{PMID}=25436857;
			}
			if($cid_data->{label}=~/van_de_Bunt_2015_/){
				$cid_data->{PMID}=26624892;
			}
			if($cid_data->{label}=~/Lepik_2017_/){
				$cid_data->{PMID}=28922377;
			}
		}
		}
		
		# statistics
		#$cid_data->{num}=$count_ri;
		#$cid_data->{num_gene}=scalar(keys %gene);
		#$cid_data->{n_gr}=scalar(keys %gr);
		
	}else{
		$cid_data="";
	}
	$sth->finish();
	$c->stash(cid_data => $cid_data);
	
	My_openri::Controller::Utils::DBDisconnect($dbh);
	
	$c->render();
}


# Render template "OpenRI_browser.html.ep"
sub OpenRI_browser {
	my $c = shift;
	
	my $dbh = My_openri::Controller::Utils::DBConnect('OpenRIdb');
	my $sth;
	
	##############
	my $json = ""; # json or ''
	##############
	
	################
	# ABC
	################
	$sth = $dbh->prepare('select Modal,Context,CID,label,num_ri,num_gene from context_info where Modal="ABC";');
	$sth->execute();
	if($sth->rows>0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{Modal}=$row[0];
			$rec->{Context}=$row[1];
			$rec->{CID}="<a href='/OpenRI/abc/".$row[2]."' target='_blank'><i class='fa fa-copyright fa-1x'></i>&nbsp;&nbsp;".$row[2]."</a>";
			$rec->{label}=$row[3];
			$rec->{num_ri}=$row[4];
			$rec->{num_gene}=$row[5];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_cid_abc => $json);
	
	################
	# PCHiC
	################
	$sth = $dbh->prepare('select Modal,Context,CID,label,num_ri,num_gene from context_info where Modal="PCHiC";');
	$sth->execute();
	if($sth->rows>0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{Modal}=$row[0];
			$rec->{Context}=$row[1];
			$rec->{CID}="<a href='/OpenRI/pchic/".$row[2]."' target='_blank'><i class='fa fa-copyright fa-1x'></i>&nbsp;&nbsp;".$row[2]."</a>";
			$rec->{label}=$row[3];
			$rec->{num_ri}=$row[4];
			$rec->{num_gene}=$row[5];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_cid_pchic => $json);
	
	################
	# QTL
	################
	$sth = $dbh->prepare('select Modal,Context,CID,label,num_ri,num_gene from context_info where Modal="QTL";');
	$sth->execute();
	if($sth->rows>0){
		my @data;
		while (my @row = $sth->fetchrow_array) {
			my $rec;
			$rec->{Modal}=$row[0];
			$rec->{Context}=$row[1];
			$rec->{CID}="<a href='/OpenRI/qtl/".$row[2]."' target='_blank'><i class='fa fa-copyright fa-1x'></i>&nbsp;&nbsp;".$row[2]."</a>";
			$rec->{label}=$row[3];
			$rec->{num_ri}=$row[4];
			$rec->{num_gene}=$row[5];
			
			push @data,$rec;
		}
		print STDERR scalar(@data)."\n";
		$json = encode_json(\@data);
	}
	$sth->finish();
	$c->stash(rec_cid_qtl => $json);
	
	################
	# realtime
	################
	my $datestring = strftime "%Y-%m-%d", localtime;
	$sth = $dbh->prepare('select Modal,CID,num_ri from context_info;');
	$sth->execute();
	my %modal;
	my $count_cid=0;
	my $count_ri=0;
	if($sth->rows>0){
		while (my @row = $sth->fetchrow_array) {
			$modal{$row[0]}=1;
			$count_cid++;
			$count_ri=$count_ri + $row[2];
		}
	}
	$sth->finish();
	my $realtime_data;
	$realtime_data->{Date}=$datestring;
	$realtime_data->{Modal}=scalar(keys %modal);
	$realtime_data->{CID}=$count_cid;
	$realtime_data->{RI}=$count_ri;
	$c->stash(realtime_data => $realtime_data);
	
	My_openri::Controller::Utils::DBDisconnect($dbh);
	
  	$c->render();
}


# Render template "OpenRI_RI2Terms.html.ep"
sub OpenRI_RI2Terms {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
  	my $regionlist = $c->param('regionlist');
  	my $build_conversion = $c->param('build') || 'NA'; # by default: NA
	my $crosslink = $c->param('crosslink') || 'proximity_10000';
  	my $obo = $c->param('obo') || 'GOMF'; # by default: GOMF
  	
	my $num_genes = $c->param('num_genes') || 'NULL'; # by default: NA
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($regionlist)){
		my $tmpFolder = $My_openri::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.Regions.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'RI2Terms.Regions.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'RI2Terms.Regions.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $regionlist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_openri::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openri'){
			# mac
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openri";
		}elsif(-e '/var/www/html/bigdata_openri'){
			# huawei: www.openridb.com
			$placeholder="/var/www/html/bigdata_openri";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", build.conversion="", crosslink="", obo="", num.genes="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# for test
	if(0){
		#cd ~/Sites/XGR/OpenRI-site
		library(tidyverse)
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_fdb"
		placeholder <- "/Users/hfang/Sites/SVN/github/bigdata_openri"
		
		#####################
		# for eg_RI2Terms_PMID35751107TableS2.txt
		input.file <- "~/Sites/XGR/OpenRI-site/app/examples/eg_PMID35751107TableS2.txt"
		res <- read_delim(input.file, delim="\t") %>% filter(padj<0.05) %>% select(region)
		res %>% write_delim("~/Sites/XGR/OpenRI-site/app/examples/eg_RI2Terms_PMID35751107TableS2.txt", delim="\t")
		#####################
		
		input.file <- "~/Sites/XGR/OpenRI-site/app/examples/eg_RI2Terms_PMID35751107TableS2.txt"
		data <- read_delim(input.file, delim="\t") %>% as.data.frame()
		
		format <- "chr:start-end"
		build.conversion <- c(NA,"hg38.to.hg19","hg18.to.hg19")
		
		crosslink <- "ABC_Encode_PMID33828297"
		crosslink <- "ABC_Roadmap_PMID33828297"
		crosslink <- "ABC_PMID33828297"
		crosslink <- "PCHiC_PMID31501517"
		crosslink <- "PCHiC_PMID27863249"
		crosslink <- "PCHiC_PMID31367015"
		crosslink <- "PCHiC"
		crosslink <- "QTL_pQTL_PMID34857953"
		crosslink <- "QTL_eQTLGen_PMID32913098"
		crosslink <- "QTL_eQTLCatalogue_GTEx"
		crosslink <- "QTL_eQTLCatalogue_Others"
		crosslink <- "QTL_eQTLCatalogue_PMID34493866"
		
		num.genes <- NULL
		obo <- "GOMF"
	}
	
	# read input file
	data <- read_delim(input.file, delim="\t") %>% as.data.frame()
	
	if(num.genes == "NULL"){
		num.genes <- NULL
	}else{
		num.genes <- as.numeric(num.genes)
	}
	
	# replace RGB_PCHiC_ with RGB.PCHiC_
	crosslink <- str_c("OR.", crosslink)
	
	xGene <- oGR2xGenes(data[,1], format="chr:start-end", build.conversion=build.conversion, crosslink=crosslink, placeholder=placeholder)
	
	set <- oRDS(str_c("org.Hs.eg", obo), placeholder=placeholder)
	background <- set$info %>% pull(member) %>% unlist() %>% unique()
	if(is.null(num.genes)){
		vec_genes <- xGene$xGene %>% reframe(GScore=max(GScore), .by=Gene) %>% arrange(-GScore) %>% pull(Gene)
	}else{
		vec_genes <- xGene$xGene %>% reframe(GScore=max(GScore), .by=Gene) %>% arrange(-GScore) %>% top_n(num.genes, GScore) %>% pull(Gene)
	}
	eset <- vec_genes %>% oSEA(set, background, test="fisher", min.overlap=3)

	if(class(eset)=="eSET"){
		# *_LG.xlsx
		output.file.LG <- gsub(".txt$", "_LG.xlsx", output.file, perl=T)
		df_LG <- xGene$xGene %>% reframe(GScore=max(GScore), .by=c(Gene,Description)) %>% arrange(-GScore)
		df_LG %>% openxlsx::write.xlsx(output.file.LG)
		
		# *_LG_evidence.xlsx
		output.file.LG_evidence <- gsub(".txt$", "_LG_evidence.xlsx", output.file, perl=T)
		df_evidence <- xGene$Evidence %>% transmute(dGR,GR,Gene,Context) %>% distinct()
		df_evidence %>% openxlsx::write.xlsx(output.file.LG_evidence)

		# RI2Terms.*.txt
		df_eTerm <- eset %>% oSEAextract()
		df_eTerm %>% write_delim(output.file, delim="\t")
		
		# *_enrichment.xlsx
		output.file.enrichment <- gsub(".txt$", ".xlsx", output.file, perl=T)
		df_eTerm %>% openxlsx::write.xlsx(output.file.enrichment)
		#df_eTerm %>% openxlsx::write.xlsx("/Users/hfang/Sites/XGR/OpenRI-site/app/examples/RI2Terms_enrichment.xlsx")
		
		# Dotplot
		message(sprintf("Drawing dotplot (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		gp_dotplot <- df_eTerm %>% mutate(name=str_c(name)) %>% oSEAdotplot(FDR.cutoff=0.05, label.top=5, size.title="Number of genes", label.direction.y=c("left","right","none")[3], colors=c("lightpink","coral3"))
		output.file.dotplot.pdf <- gsub(".txt$", "_dotplot.pdf", output.file, perl=T)
		ggsave(output.file.dotplot.pdf, gp_dotplot, device=cairo_pdf, width=5, height=4)
		output.file.dotplot.png <- gsub(".txt$", "_dotplot.png", output.file, perl=T)
		ggsave(output.file.dotplot.png, gp_dotplot, type="cairo", width=5, height=4)
		
		# Forest plot
		if(1){
			message(sprintf("Drawing forest (%s) ...", as.character(Sys.time())), appendLF=TRUE)
			#zlim <- c(0, -log10(df_eTerm$adjp) %>% max() %>% ceiling())
			zlim <- c(0, -log10(df_eTerm$adjp) %>% quantile(0.95) %>% ceiling())
			gp_forest <- df_eTerm %>% mutate(name=str_c(name)) %>% oSEAforest(top=10, colormap="spectral.top", color.title=expression(-log[10]("FDR")), zlim=zlim, legend.direction=c("auto","horizontal","vertical")[3], sortBy=c("or","none")[1], size.title="Number\nof genes", wrap.width=50)		
			output.file.forestplot.pdf <- gsub(".txt$", "_forest.pdf", output.file, perl=T)
			ggsave(output.file.forestplot.pdf, gp_forest, device=cairo_pdf, width=5, height=3.5)
			output.file.forestplot.png <- gsub(".txt$", "_forest.png", output.file, perl=T)
			ggsave(output.file.forestplot.png, gp_forest, type="cairo", width=5, height=3.5)
		}
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/my_xgrplus/public
		## but outputs at public/tmp/eV2CG.Regions.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		ls_rmd$sT <- sT
		ls_rmd$eT <- eT
		ls_rmd$data_input <- xGene$GR
		ls_rmd$xlsx_LG <- gsub("public/", "", output.file.LG, perl=T)
		ls_rmd$xlsx_LG_evidence <- gsub("public/", "", output.file.LG_evidence, perl=T)
		ls_rmd$num_LG <- nrow(df_LG)
		ls_rmd$num_genes <- length(vec_genes)
		ls_rmd$xlsx_enrichment <- gsub("public/", "", output.file.enrichment, perl=T)
		ls_rmd$pdf_dotplot <- gsub("public/", "", output.file.dotplot.pdf, perl=T)
		ls_rmd$png_dotplot <- gsub("public/", "", output.file.dotplot.png, perl=T)
		ls_rmd$pdf_forestplot <- gsub("public/", "", output.file.forestplot.pdf, perl=T)
		ls_rmd$png_forestplot <- gsub("public/", "", output.file.forestplot.png, perl=T)

		## rmarkdown
		
		output_dir <- gsub("RI2Terms.*", "", output.file, perl=T)
		message(sprintf("html at %s", output_dir), appendLF=TRUE)
		
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_RI2Terms.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)
library(GenomicRanges)

# huawei
vec <- list.files(path='/root/OpenRI/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenRI/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", build.conversion=\"$build_conversion\", crosslink=\"$crosslink\", obo=\"$obo\", num.genes=\"$num_genes\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- RI2Terms: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_openri::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_RI2Terms.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_RI2Terms.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_RI2Terms (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_RI2Terms.html";
			#public/tmp/digit16_RMD_RI2Terms.html
			print STDERR "RMD_RI2Terms (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_RI2Terms.html
				print STDERR "RMD_RI2Terms (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


# Render template "OpenRI_RI2Genes.html.ep"
sub OpenRI_RI2Genes {
  	my $c = shift;
	
	my $ip = $c->tx->remote_address;
	print STDERR "Remote IP address: $ip\n";
	
	my $host = $c->req->url->to_abs->host;
	my $port = $c->req->url->to_abs->port;
	my $host_port = "http://".$host.":".$port."/";
	print STDERR "Server available at ".$host_port."\n";
	
	if($c->req->is_limit_exceeded){
		return $c->render(status => 400, json => { message => 'File is too big.' });
	}
	
  	my $regionlist = $c->param('regionlist');
  	my $build_conversion = $c->param('build') || 'NA'; # by default: NA
	my $crosslink = $c->param('crosslink') || 'proximity_10000';
  	
  	# The output json file (default: '')
	my $ajax_txt_file='';
  	# The output html file (default: '')
	my $ajax_rmd_html_file='';
	
	# The output _priority.xlsx file (default: '')
	my $ajax_priority_xlsx_file='';
  	
	# The output _manhattan.pdf file (default: '')
	my $ajax_manhattan_pdf_file='';
  	
  	if(defined($regionlist)){
		my $tmpFolder = $My_openri::Controller::Utils::tmpFolder; # public/tmp
		
		# 14 digits: year+month+day+hour+minute+second
		my $datestring = strftime "%Y%m%d%H%M%S", localtime;
		# 2 randomly generated digits
		my $rand_number = int rand 99;
		my $digit16 =$datestring.$rand_number."_".$ip;

		my $input_filename=$tmpFolder.'/'.'data.Regions.'.$digit16.'.txt';
		my $output_filename=$tmpFolder.'/'.'RI2Genes.Regions.'.$digit16.'.txt';
		my $rscript_filename=$tmpFolder.'/'.'RI2Genes.Regions.'.$digit16.'.r';
	
		my $my_input="";
		my $line_counts=0;
		foreach my $line (split(/\r\n|\n/, $regionlist)) {
			next if($line=~/^\s*$/);
			$line=~s/\s+/\t/;
			$my_input.=$line."\n";
			
			$line_counts++;
		}
		# at least two lines otherwise no $input_filename written
		if($line_counts >=2){
			My_openri::Controller::Utils::export_to_file($input_filename, $my_input);
		}
		
		my $placeholder;
		if(-e '/Users/hfang/Sites/SVN/github/bigdata_openri'){
			# mac
			$placeholder="/Users/hfang/Sites/SVN/github/bigdata_openri";
		}elsif(-e '/var/www/html/bigdata_openri'){
			# huawei: www.openridb.com
			$placeholder="/var/www/html/bigdata_openri";
		}
		
##########################################
# BEGIN: R
##########################################
my $my_rscript='
#!/home/hfang/R-3.6.2/bin/Rscript --vanilla
#/home/hfang/R-3.6.2/lib/R/library
# rm -rf /home/hfang/R-3.6.2/lib/R/library/
# Call R script, either using one of two following options:
# 1) R --vanilla < $rscript_file; 2) Rscript $rscript_file
';

# for generating R function
$my_rscript.='
R_pipeline <- function (input.file="", output.file="", build.conversion="", crosslink="", placeholder="", host.port="", ...){
	
	sT <- Sys.time()
	
	# read input file
	data <- read_delim(input.file, delim="\t") %>% as.data.frame()
	
	# replace RGB_PCHiC_ with RGB.PCHiC_
	crosslink <- str_c("OR.", crosslink)
	
	xGene <- oGR2xGenes(data[,1], format="chr:start-end", build.conversion=build.conversion, crosslink=crosslink, placeholder=placeholder)

	if(1){
		# *_LG.xlsx
		output.file.LG <- gsub(".txt$", "_LG.xlsx", output.file, perl=T)
		df_LG <- xGene$xGene %>% reframe(GScore=max(GScore), .by=c(Gene,Description)) %>% arrange(-GScore)
		df_LG %>% openxlsx::write.xlsx(output.file.LG)
		
		# RI2Genes.*.txt
		xGene$xGene %>% write_delim(output.file, delim="\t")
		
		# *_LG_evidence.xlsx
		output.file.LG_evidence <- gsub(".txt$", "_LG_evidence.xlsx", output.file, perl=T)
		df_evidence <- xGene$Evidence %>% transmute(dGR,GR,Gene,Context) %>% distinct()
		df_evidence %>% openxlsx::write.xlsx(output.file.LG_evidence)
		
		######################################
		# RMD
		## R at /Users/hfang/Sites/XGR/XGRplus-site/my_xgrplus/public
		## but outputs at public/tmp/eV2CG.Regions.STRING_high.72959383_priority.xlsx
		######################################
		message(sprintf("RMD (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		
		if(1){
		
		eT <- Sys.time()
		runtime <- as.numeric(difftime(strptime(eT, "%Y-%m-%d %H:%M:%S"), strptime(sT, "%Y-%m-%d %H:%M:%S"), units="secs"))
		
		ls_rmd <- list()
		ls_rmd$host_port <- host.port
		ls_rmd$runtime <- str_c(runtime," seconds")
		ls_rmd$sT <- sT
		ls_rmd$eT <- eT
		ls_rmd$data_input <- xGene$GR
		ls_rmd$xlsx_LG <- gsub("public/", "", output.file.LG, perl=T)
		ls_rmd$xlsx_LG_evidence <- gsub("public/", "", output.file.LG_evidence, perl=T)
		ls_rmd$num_LG <- nrow(df_LG)

		## rmarkdown
		
		output_dir <- gsub("RI2Genes.*", "", output.file, perl=T)
		message(sprintf("html at %s", output_dir), appendLF=TRUE)
		
		if(file.exists("/usr/local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
		}else if(file.exists("/home/hfang/.local/bin/pandoc")){
			Sys.setenv(RSTUDIO_PANDOC="/home/hfang/.local/bin")
		}else{
			message(sprintf("PANDOC is NOT FOUND (%s) ...", as.character(Sys.time())), appendLF=TRUE)
		}
		rmarkdown::render("public/RMD_RI2Genes.Rmd", bookdown::html_document2(number_sections=F,theme=c("readable","united")[1], hightlight="default"), output_dir=output_dir)

		}
	}
	
	##########################################
}
';

# for calling R function
$my_rscript.="
startT <- Sys.time()

library(tidyverse)
library(GenomicRanges)

# huawei
vec <- list.files(path='/root/OpenRI/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))
# mac
vec <- list.files(path='/Users/hfang/Sites/XGR/OpenRI/R', pattern='.r', full.names=T)
ls_tmp <- lapply(vec, function(x) source(x))

R_pipeline(input.file=\"$input_filename\", output.file=\"$output_filename\", build.conversion=\"$build_conversion\", crosslink=\"$crosslink\", placeholder=\"$placeholder\", host.port=\"$host_port\")

endT <- Sys.time()
runTime <- as.numeric(difftime(strptime(endT, '%Y-%m-%d %H:%M:%S'), strptime(startT, '%Y-%m-%d %H:%M:%S'), units='secs'))
message(str_c('\n--- RI2Genes: ',runTime,' secs ---\n'), appendLF=TRUE)
";

# for calling R function
My_openri::Controller::Utils::export_to_file($rscript_filename, $my_rscript);
# $input_filename (and $rscript_filename) must exist
if(-e $rscript_filename and -e $input_filename){
    chmod(0755, "$rscript_filename");
    
    my $command;
    if(-e '/home/hfang/R-3.6.2/bin/Rscript'){
    	# galahad
    	$command="/home/hfang/R-3.6.2/bin/Rscript $rscript_filename";
    }else{
    	# mac and huawei
    	$command="/usr/local/bin/Rscript $rscript_filename";
    }
    
    if(system($command)==1){
        print STDERR "Cannot execute: $command\n";
    }else{
		if(! -e $output_filename){
			print STDERR "Cannot find $output_filename\n";
		}else{
			my $tmp_file='';
			
			## notes: replace 'public/' with '/'
			$tmp_file=$output_filename;
			if(-e $tmp_file){
				$ajax_txt_file=$tmp_file;
				$ajax_txt_file=~s/^public//g;
				print STDERR "TXT locates at $ajax_txt_file\n";
			}
			
			##########################
			### for RMD_RI2Genes.html
			##########################
			$tmp_file=$tmpFolder."/"."RMD_RI2Genes.html";
			#public/tmp/RMD_eV2CG.html	
			print STDERR "RMD_RI2Genes (local & original) locates at $tmp_file\n";
			$ajax_rmd_html_file=$tmpFolder."/".$digit16."_RMD_RI2Genes.html";
			#public/tmp/digit16_RMD_RI2Genes.html
			print STDERR "RMD_RI2Genes (local & new) locates at $ajax_rmd_html_file\n";
			if(-e $tmp_file){
				# do replacing
    			$command="mv $tmp_file $ajax_rmd_html_file";
				if(system($command)==1){
					print STDERR "Cannot execute: $command\n";
				}
				$ajax_rmd_html_file=~s/^public//g;
				#/tmp/digit16_RMD_RI2Genes.html
				print STDERR "RMD_RI2Genes (server) locates at $ajax_rmd_html_file\n";
			}
			
		}
    }
}else{
    print STDERR "Cannot find $rscript_filename\n";
}
##########################################
# END: R
##########################################
	
	}
	
	# stash $ajax_txt_file;
	$c->stash(ajax_txt_file => $ajax_txt_file);
	
	# stash $ajax_rmd_html_file;
	$c->stash(ajax_rmd_html_file => $ajax_rmd_html_file);

	
  	$c->render();

}


1;
