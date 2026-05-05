project('chantricks',
  version:            '1.0.10',
  meson_version:      '>=1.3.0',
)
# Pure-Tcl module: chantricks is a single .tcl file distributed as a
# Tcl Module (.tm). No compiler needed. Meson's implicit 'c' language
# default is unused.

tcl_dep        = dependency('tcl')
tclver_full    = tcl_dep.version()
tclver_parts   = tclver_full.split('.')
tclver_major   = tclver_parts[0]
tm_install_dir = tcl_dep.get_variable('libdir') / 'tcl' + tclver_major / 'site-tcl'

# Build the .tm file (a verbatim copy of the source).
master_tm_name = meson.project_name() + '-' + meson.project_version() + '.tm'

chantricks_tm = configure_file(
  input:          'chantricks.tcl',
  output:         master_tm_name,
  copy:           true,
  install:        true,
  install_dir:    tm_install_dir,
  install_tag:    meson.is_subproject() ? 'deps' : 'runtime',
)

# Generate a pkg-config file. Pure-Tcl module — no Cflags / Libs, just
# the `tcl_tm_path` variable so consumers (meson, cmake, plain shell)
# can locate the install dir uniformly. The same variable is exposed
# on declare_dependency below so subproject-fallback consumers get the
# same interface as system-installed ones.
pc_conf = configuration_data()
pc_conf.set('PACKAGE_NAME',     meson.project_name())
pc_conf.set('PACKAGE_VERSION',  meson.project_version())
pc_conf.set('TCL_MAJOR',        tclver_major)

configure_file(
  input:          meson.project_name() + '.pc.in',
  output:         meson.project_name() + '.pc',
  configuration:  pc_conf,
  install:        true,
  install_dir:    tcl_dep.get_variable('libdir') / 'pkgconfig',
  install_tag:    meson.is_subproject() ? 'deps' : 'runtime',
)

# Subproject consumers rely on the variables here matching the .pc
# variables key-for-key — `dependency(name, fallback: ...).get_variable()`
# returns from one or the other depending on which path resolved.
chantricks_dep = declare_dependency(
  variables: {
    'tcl_tm_path': meson.current_build_dir(),
    'version':     meson.project_version(),
  },
)
meson.override_dependency(meson.project_name(), chantricks_dep)

# Devenv so `meson devenv -C <builddir> tclsh` picks up this package
# without having to install it.
devenv = environment()
devenv.prepend('TCLLIBPATH', meson.current_build_dir(), separator: ' ')
meson.add_devenv(devenv)

# Tests
if not meson.is_subproject()
  tclsh = find_program(
    tcl_dep.get_variable('exec_prefix') / 'bin/tclsh' + tclver_parts[0] + '.' + tclver_parts[1].split('a')[0].split('b')[0],
    tcl_dep.get_variable('exec_prefix') / 'bin/tclsh',
    'tclsh',
    required: false,
  )
  if tclsh.found()
    test('tcltest', tclsh,
      args: [
        meson.project_source_root() / 'tests/all.tcl',
        '-load',
        'package require ' + meson.project_name() + ' ' + meson.project_version(),
      ],
      env:      {'TCL' + tclver_parts[0] + '_' + tclver_parts[1] + '_TM_PATH': meson.current_build_dir()},
      verbose:  true,
      timeout:  60,
    )
  endif
endif

# vim: foldmethod=marker foldmarker=<<<,>>> shiftwidth=2 expandtab
