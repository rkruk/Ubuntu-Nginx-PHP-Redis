# Contributing to Ubuntu-Nginx-PHP-Redis

Thank you for your interest in contributing to this WordPress automation script! 

## How to Contribute

### Reporting Issues
- Use the GitHub issue tracker to report bugs
- Include detailed information about your environment (OS version, server specs, etc.)
- Provide steps to reproduce the issue
- Include relevant log outputs from `/var/log/wordpress-setup.log`

### Suggesting Enhancements
- Open an issue with the tag "enhancement"
- Clearly describe the proposed feature
- Explain why this enhancement would be useful

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Test your changes** on a clean Ubuntu/Debian server
4. **Commit your changes** (`git commit -m 'Add amazing feature'`)
5. **Push to the branch** (`git push origin feature/amazing-feature`)
6. **Open a Pull Request**

### Guidelines

- Follow existing code style and conventions
- Test changes thoroughly before submitting
- Add comments for complex logic
- Update documentation if needed
- Ensure the script remains compatible with Ubuntu 20.04+ and Debian 10+

### Testing

Before submitting a pull request:
- Test the script on a fresh server installation
- Verify all features work as expected
- Check that SSL certificates are properly installed
- Ensure WordPress sites are accessible and functional
- Verify Redis caching is working
- Test backup functionality

### Code of Conduct

- Be respectful and constructive in discussions
- Help others learn and grow
- Focus on what is best for the community
- Show empathy towards other community members

## Development Setup

1. Clone the repository
2. Set up a test environment (VM or container)
3. Make your changes
4. Test thoroughly
5. Submit your contribution

Thank you for contributing!
