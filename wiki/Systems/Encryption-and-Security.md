# Encryption and Security

AE3 includes security-style gameplay through user accounts, file permissions, passworded files, optional security commands, and encrypted file setup.

## User Accounts

User accounts control login credentials and home folders. Use accounts when players should need a username and password to access a laptop.

## File Permissions

Permissions control who can read, write, or execute files and folders. In editor modules, permissions are shown as owner and everyone checkboxes.

Use permissions sparingly for player-facing missions. If players cannot read an important clue, make sure they have a way to learn the right credentials or route around the restriction.

## Passworded Files

Passworded files require a specific password before players can see the protected content.

Good passworded-file design:

- Put the password somewhere discoverable.
- Avoid random guessing.
- Make the locked file name meaningful.
- Give players a reason to know it is worth opening.

## Encrypted Files

The Add File module can create encrypted content. Use this when the mission includes an encryption or cracking task.

Good encryption design:

- Tell players what tool or method is relevant.
- Provide enough clues to solve it.
- Avoid putting mandatory mission progress behind unclear cryptography.

## Security Commands

Some laptops may include commands such as crypto or crack. These are installed by mission setup, not guaranteed on every laptop.

If the mission expects players to use a security command, make sure:

- The laptop exposes terminal access.
- The command is installed.
- Players can discover the command through `help`, `man`, notes, or training.

Script references belong in [ArmaOS API](../Reference/ArmaOS-API.md) and [Terminal Commands](../Reference/Terminal-Commands.md).
