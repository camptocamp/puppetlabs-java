# Defined Type java::adopt
#
# Description
# Installs OpenJDK Java built with AdoptOpenJDK with the Hotspot JVM.
#
# Install one or more versions of AdoptOpenJDK Java.
#
# Currently only Linux RedHat, Amazon and Debian are supported.
#
# Parameters
# [*version*]
# Version of Java to install, e.g. '8' or '9'. Default values for major and minor
# versions will be used.
#
# [*version_major*]
# Major version which should be installed, e.g. '8u101' or '9.0.4'. Must be used together with
# version_minor.
#
# [*version_minor*]
# Minor version which should be installed, e.g. 'b12' (for version = '8') or '11' (for version != '8').
# Must be used together with version_major.
#
# [*java_edition*]
# Type of Java Edition to install, jdk or jre.
#
# [*ensure*]
# Install or remove the package.
#
# [*proxy_server*]
# Specify a proxy server, with port number if needed. ie: https://example.com:8080. (passed to archive)
#
# [*proxy_type*]
# Proxy server type (none|http|https|ftp). (passed to archive)
#
# [*basedir*]
# Directory under which the installation will occur. If not set, defaults to
# /usr/lib/jvm for Debian and /usr/java for RedHat.
#
# [*manage_basedir*]
# Whether to manage the basedir directory.  Defaults to false.
# Note: /usr/lib/jvm is managed for Debian by default, separate from this parameter.
#
# [*package_type*]
# Type of installation package for specified version of java. java 6 comes
# in a few installation package flavors and we need to account for them.
# Optional forced package types: rpm, rpmbin, tar.gz
#
# Variables
# [*release_major*]
# Major version release number for java. Used to construct download URL.
#
# [*release_minor*]
# Minor version release number for java. Used to construct download URL.
#
# [*install_path*]
# Base install path for specified version of java. Used to determine if java
# has already been installed.
#
# [*os*]
# java OS type.
#
# [*destination*]
# Destination directory to save java installer to.  Usually /tmp on Linux and
# C:\TEMP on Windows.
#
# [*creates_path*]
# Fully qualified path to java after it is installed. Used to determine if
# java is already installed.
#
# [*arch*]
# java architecture type.
#
# [*package_name*]
# Name of the java installation package to download from github.
#
# [*install_command*]
# Installation command used to install java. Installation commands
# differ by package_type. 'bin' types are installed via shell command. 'rpmbin'
# types have the rpms extracted and then forcibly installed. 'rpm' types are
# forcibly installed.
#
# [*spacer*]
# Spacer to be used in github download url. In major version 8 this is a simple dash
# in later versions they use a crazy plus sign, which needs to be used in urlencoded
# format
#
# [*download_folder_prefix*]
# Download folder name begins differently depending on the release. After major release
# 8, they have given it a dash. Be aware that even if you want to have a JRE, the folder
# still begins with "jdk"
#
# [*release_minor_url*]
# filled depending on major release. Until major release 8 the minor part needs to be given
# with a 'b' for build, in later versions it is a underscore or a plus sign, which needs
# to be stripped for the download url and is replaced with the given spaces (see above)
#
# [*_package_type*]
# Helper variable which gets filled depending on parameter package_type
#
# [*_basedir*]
# Helper variable which gets filled depending on parameter basedir
#
# [*_version*]
# Helper variable which gets filled depending on parameter version
#
# [*_version_int*]
# Helper variable which gets the value of $_version converted to integer
#
# [*_append_jre*]
# Helper variable which gets filled with the string "-jre" if jre was selected to build the correct install path
#
# [*_release_minor_package_name*]
# Helper variable which gets filled with the right minor string depending on the major version
#
define java::adopt (
  $ensure         = 'present',
  $version        = '8',
  $version_major  = undef,
  $version_minor  = undef,
  $java           = 'jdk',
  $proxy_server   = undef,
  $proxy_type     = undef,
  $basedir        = undef,
  $manage_basedir = true,
  $package_type   = undef,
) {

  # archive module is used to download the java package
  include ::archive

  # validate java Standard Edition to download
  if $java !~ /(jre|jdk)/ {
    fail('java must be either jre or jdk.')
  }

  # determine AdoptOpenJDK Java major and minor version, and installation path
  if $version_major and $version_minor {

    $release_major = $version_major
    $release_minor = $version_minor

    if ( $version_major[0] == '8' or $version_major[0] == '9' ) {
      $_version = $version_major[0]
    } else {
      $_version = $version_major[0,2]
    }

    $_version_int = Numeric($_version)

    if ( $java == 'jre' ) {
      $_append_jre = '-jre'
    } else {
      $_append_jre = ''
    }

    # extracted folders look like this:
    #  jdk8u202-b08
    #  jdk-9.0.4+11
    #  jdk-10.0.2+13
    #  jdk-11.0.2+9
    #  jdk-12.0.1+12
    #  jdk8u202-b08-jre
    #  jdk-9.0.4+11-jre
    # hence we need to check for the major version and build the install path according to it
    if ( $_version_int == 8 ) {
      $install_path = "jdk${release_major}-${release_minor}${_append_jre}"
    } elsif ( $_version_int > 8 ) {
      $install_path = "jdk-${release_major}+${release_minor}${_append_jre}"
    } else {
      fail ("unsupported version ${_version}")
    }

  } else {
    $_version = $version
    $_version_int = Numeric($_version)
    # use default versions if no specific major and minor version parameters are provided
    case $version {
      '8' : {
        $release_major = '8u202'
        $release_minor = 'b08'
        $install_path = "${java}8u202-b08"
      }
      '9' : {
        $release_major = '9.0.4'
        $release_minor = '11'
        $install_path = "${java}-9.0.4+11"
      }
      # minor release is given with +<number>, however package etc. works with underscore, so we use underscore here
      '10' : {
        $release_major = '10.0.2'
        $release_minor = '13'
        $install_path = "${java}-10.0.2+13"
      }
      '11' : {
        $release_major = '11.0.2'
        $release_minor = '9'
        $install_path = "${java}-11.0.2+9"
      }
      # minor release is given with +<number>, however package etc. works with underscore, so we use underscore here
      '12' : {
        $release_major = '12.0.1'
        $release_minor = '12'
        $install_path = "${java}-12.0.1+12"
      }
      default : {
        $release_major = '8u202'
        $release_minor = 'b08'
        $install_path = "${java}8u202-b08"
      }
    }
  }

  # determine package type (exe/tar/rpm), destination directory based on OS
  case $facts['kernel'] {
    'Linux' : {
      case $facts['os']['family'] {
        'RedHat', 'Amazon' : {
          if $package_type {
            $_package_type = $package_type
          } else {
            $_package_type = 'tar.gz'
          }
          if $basedir {
            $_basedir = $basedir
          } else {
            $_basedir = '/usr/java'
          }
        }
        'Debian' : {
          if $package_type {
            $_package_type = $package_type
          } else {
            $_package_type = 'tar.gz'
          }
          if $basedir {
            $_basedir = $basedir
          } else {
            $_basedir = '/usr/lib/jvm'
          }
        }
        default : {
          fail ("unsupported platform ${$facts['os']['name']}") }
      }

      $creates_path = "${_basedir}/${install_path}"
      $os = 'linux'
      $destination_dir = '/tmp/'
    }
    default : {
      fail ( "unsupported platform ${$facts['kernel']}" ) }
  }

  # set java architecture nomenclature
  $os_architecture = $facts['os']['architecture'] ? {
    undef => $facts['architecture'],
    default => $facts['os']['architecture']
  }

  case $os_architecture {
    'i386' : { $arch = 'x86-32' }
    'x86_64' : { $arch = 'x64' }
    'amd64' : { $arch = 'x64' }
    default : {
      fail ("unsupported platform ${$os_architecture}")
    }
  }

  # package name and path for download from github
  #
  # following are build based on this real life example full URLs:
  #
  # https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u202b08.tar.gz
  # https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk-9.0.4%2B11/OpenJDK9U-jdk_x64_linux_hotspot_9.0.4_11.tar.gz
  # https://github.com/AdoptOpenJDK/openjdk10-binaries/releases/download/jdk-10.0.2%2B13/OpenJDK10U-jdk_x64_linux_hotspot_10.0.2_13.tar.gz
  # https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.2%2B9/OpenJDK11U-jdk_x64_linux_hotspot_11.0.2_9.tar.gz
  # https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12.0.1%2B12/OpenJDK12U-jdk_x64_linux_hotspot_12.0.1_12.tar.gz
  # jre just replaces jdk with jre in the archive name, but not in the path name!
  # https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk-9.0.4%2B11/OpenJDK9U-jre_x64_linux_hotspot_9.0.4_11.tar.gz

  if ( $_version_int == 8 ) {
    $_release_minor_package_name = $release_minor
  } else {
    $_release_minor_package_name = "_${release_minor}"
  }

  case $_package_type {
    'tar.gz': {
      $package_name = "OpenJDK${_version}U-${java}_${arch}_${os}_hotspot_${release_major}${_release_minor_package_name}.tar.gz"
    }
    default: {
      $package_name = "OpenJDK${_version}U-${java}_${arch}_${os}_hotspot_${release_major}${_release_minor_package_name}.tar.gz"
    }
  }

  # naming convention changed after major version 8, setting variables to consider that
  # download_folder_prefix always begins with "jdk", even for jre! see comments for package_name above
  if ( $_version_int == 8 ) {
    $spacer = '-'
    $download_folder_prefix = 'jdk'
  } else {
    $spacer = '%2B'
    $download_folder_prefix = 'jdk-'
  }
  $source = "https://github.com/AdoptOpenJDK/openjdk${_version}-binaries/releases/download/${download_folder_prefix}${release_major}${spacer}${release_minor}/${package_name}"

  # full path to the installer
  $destination = "${destination_dir}${package_name}"
  notice ("Destination is ${destination}")

  case $_package_type {
    'tar.gz' : {
      $install_command = "tar -zxf ${destination} -C ${_basedir}"
    }
    default : {
      $install_command = "tar -zxf ${destination} -C ${_basedir}"
    }
  }

  case $ensure {
    'present' : {
      archive { $destination :
        ensure       => present,
        source       => $source,
        extract_path => '/tmp',
        cleanup      => false,
        creates      => $creates_path,
        proxy_server => $proxy_server,
        proxy_type   => $proxy_type,
      }
      case $facts['kernel'] {
        'Linux' : {
          case $facts['os']['family'] {
            'Debian' : {
              ensure_resource('file', $_basedir, {
                ensure => directory,
              })
              $install_requires = [Archive[$destination], File[$_basedir]]
            }
            default : {
              $install_requires = [Archive[$destination]]
            }
          }

          if $manage_basedir {
            if (!defined(File[$_basedir])) {
              file { $_basedir:
                ensure => 'directory',
                before => Exec["Install AdoptOpenJDK java ${java} ${_version} ${release_major} ${release_minor}"],
              }
            }
          }

          exec { "Install AdoptOpenJDK java ${java} ${_version} ${release_major} ${release_minor}" :
            path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
            command => $install_command,
            creates => $creates_path,
            require => $install_requires
          }

        }
        default : {
          fail ("unsupported platform ${$facts['kernel']}")
        }
      }
    }
    default : {
      notice ("Action ${ensure} not supported.")
    }
  }

}