package Net::Mail;
use strict;
use MIME::Base64;

#############################################################################
#ver 1.2.0 beta
#2004-08-30 1.2.0 beta release
#2004-08-29 2.0.0 developing
#2004-08-24 release 1.0.0
#############################################################################

#############################################################################
#Product: Perl lib Net::Mail
#Author:钱宇 
#Email: qian.yu@adways.net group1104@yahoo.com
#Version: ver 1.2.0 beta
#Hompage: http://www.foolfish.com.ru
#This file is encoding by utf8
#Please get the latest version of DateTime from my homepage or send me email
#############################################################################

#############################################################################
#This module can help you send mail via esmtp(smtp with simple auth) or sendmail
#usage: via esmtp
#		my $mail = Net::Mail->new(
#			{smtp_server=>'smtp.foolfish.com.ru',smtp_port=>25,type=>'esmtp',smtp_usr=>'foolfish',smtp_pass=>'123456',from=>'foolfish@foolfish.com.ru'});
#		if($mail->send(['email1@yeah.net','email2@yahoo.com','email3@msn.com'],'subject', "Content-type: text/plain; Charset=gbk\n\n".'Hello World Esmtp!'))
#		{
#    		print 'send to mail OK.\n';
#		}
#		
#		via sendmail
#		my $mail = Net::Mail->new(
#			{type=>'sendmail',from=>'foolfish@foolfish.com.ru'});
#
#		if($mail->send(['email1@yeah.net','email2@yahoo.com','email3@msn.com'],'subject', "Content-type: text/plain; Charset=gbk\n\n".'Hello World sendmail!'))
#		{
#    		print 'send to mail OK.\n';
#		}
#
#############################################################################


#############################################################################
#you can use CGI module to write mail content
#my $q=CGI->new;
#my $body="Hello World";
#my $Content=$q->header('text/plain').$body;
#my $Content=$q->header('text/html').$body;
#$mail->send(['email1@yeah.net','email2@yahoo.com','email3@msn.com'],'subject', $Content);
#############################################################################


#sub new;
#===return new instace of Net::Mail object;
#===usage1: Net::Mail->new({type=>'esmtp',smtp_server,[smtp_port=>25],smtp_usr,smtp_pass,from});
#===usage2: Net::Mail->new({type=>'sendmail',from});


#sub send;
#===send mail;return 1 if succ,return undef if fail
#===usage: $mail->send(ToListArrayRef,Subject,Content);
#===ToListArrayRef: [email1,email2,email3...];
#===Subject: string
#===Content: mail head and mail body,you have to write head by yourself,just like write a CGI,
#===         "Content-type: text/plain; Charset=gbk\n\n".'Hello World Esmtp!'



sub new
{
	my $paramCount=scalar @_;
	my $flag;
	my $param;
	if($paramCount==2&&$_[0] eq 'Net::Mail' && ref $_[1] eq 'HASH')
	{
		$param=$_[1];
		$flag=1;
	}
	else{$flag=404;}
	
	if($flag==1)
	{
		my $self = bless [],'Net::Mail';
		$self->[0]=defined($param->{'type'})?$param->{'type'}:undef;
		if($self->[0] eq 'esmtp')
		{
			if(defined($param->{'smtp_server'})
			   &&defined($param->{'smtp_usr'})
			   &&defined($param->{'smtp_pass'})
			   &&defined($param->{'from'}))
			{
				$self->[1]=trim($param->{'smtp_server'});
				$self->[2]=trim($param->{'smtp_port'});
				$self->[3]=trim($param->{'smtp_usr'});
				$self->[4]=isNum($param->{'smtp_pass'})?toInt($param->{'smtp_pass'}):25;
				$self->[5]=trim($param->{'from'});
				return $self;
			}
		}elsif($self->[0] eq 'smtp'){}
		elsif($self->[0] eq 'sendmail')
		{
			if(defined($param->{'from'}))
			{
				$self->[1]=trim($param->{'from'});
				return $self;
			}
		}
	}
	elsif($flag==404){}else{};
	die 'Net::Mail::new() usage error!';
}


sub send
{
	my ($self,$to, $subject, $content) = @_;
	my $sendstat=0;
	if ($self->[0] eq 'smtp'){}
	elsif ($self->[0] eq 'esmtp')
	{
		$sendstat = 1 if (&_smtp_mail($to,$self->[5],$self->[1],$self->[2],$self->[3],$self->[4],$subject,$content));
	}elsif ($self->[0] eq 'sendmail'){
		$sendstat = 1 if ($self->_sendmail($to,$subject, $content));
	}
	return $sendstat;
}

sub _sendmail {
	my $self=shift;
	my ($toList,$subject, $content) = @_;
	my $toStr='';
	foreach my $i(@$toList)
	{
		$toStr.="<$i>,";
	}
	chop($toStr);
	return 0 unless (open(MAIL, "| sendmail -t"));
	print MAIL "To: $toStr\n";
	print MAIL "From: ".$self->[1]."\r\n";
	print MAIL "Subject: $subject\r\n";
	print MAIL "$content\r\n";
	print MAIL "\r\n.\r\n";
	print MAIL "\n.";
	close(MAIL);
    return 1;
}

sub _smtp_mail
{
	my($toList,$from,$host,$port,$usrName,$usrPass,$subject,$content)=@_;
	
	my ($name, $aliases, $proto, $type, $len, $thataddr);
	my $AF_INET = 2;
	my $SOCK_STREAM = 1;
	my $SOCKADDR = 'S n a4 x8';
	
	($name, $aliases, $proto) = getprotobyname('tcp');
	($name, $aliases, $type, $len, $thataddr) = gethostbyname($host);
	my $this = pack($SOCKADDR, $AF_INET, 0);
	my $that = pack($SOCKADDR, $AF_INET, $port, $thataddr);
	socket(S, $AF_INET, $SOCK_STREAM, $proto);
	bind(S, $this);
	connect(S, $that);
	
	select(S);
	$| = 1;
	select(STDOUT);
	my $a = <S>;
	if ($a !~ /^2/) {close(S);return $a;}
	
	print S "EHLO localhost\r\n";
	$a = <S>;
	print S "AUTH LOGIN\r\n";
	$a = <S>;
	my $encode_smtpuser = encode_base64($usrName,'');
	print S "$encode_smtpuser\r\n";
	$a = <S>;
	my $encode_smtppass = encode_base64($usrPass,'');
	print S "$encode_smtppass\r\n";
	$a = <S>;
	return undef if ($a =~ /fail/i);
	
	print S "MAIL FROM: <$from>\r\n";
	$a = <S>;
	
	my $toStr='';
	foreach my $i(@$toList)
	{
		$toStr.="<$i>,";
		print S "RCPT TO: <$i>\r\n";
		$a = <S>;
	}
	chop($toStr);
	
	print S "DATA\r\n";
	$a = <S>;
	print S "From: $from\r\n";
	print S "To: $toStr\r\n";
	print S "Subject: $subject\r\n";
	print S "$content\r\n";
	print S "\r\n.\r\n";
	return 1;
}

#################################################
#Util
#################################################

sub trim
{
    local $_ = shift;
    unless(defined($_)){return undef;}
    s/^\s+//, s/\s+$//;
    $_ ;
}

sub toInt
{
	local $_ = trim(shift);
	if(defined&&/^-?\d+\.?\d*$/){
	    return int;
	    }
	else{
	    die 'Error:toInt';
	    }
}

sub isNum
{
	local $_ = trim(shift);
	return defined&&/^-?\d+\.?\d*$/;
}

1;
    
