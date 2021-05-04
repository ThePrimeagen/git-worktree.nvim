test:
	GIT_WORKTREE_NVIM_LOG=fatal nvim --headless --noplugin -u tests/minimal_init.vim -c "PlenaryBustedDirectory tests/ { minimal_init = './tests/minimal_init.vim' }"
