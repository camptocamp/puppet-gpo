class gpo::install {
  package { 'lgpo':
    ensure   => installed,
    provider => 'chocolatey',
  } -> Gpo <||>
}
