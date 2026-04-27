# AppalachianTrail
Project for CSCI-4350 Software Engineering II
Trello Board: https://trello.com/b/DD2cWq1z

**Product Vision**

The vision of Appalachian Trail is to create a browser-based roguelike top-down shooter where players fight their way across a reversed American frontier. Instead of traveling west like the classic Oregon Trail, players begin in Oregon and battle their way east toward the Appalachian Mountains.

Players will progress through multiple regions including mountains, deserts, plains, snow-covered areas, forests, and Appalachia. Each region contains unique enemies, environmental themes, and bosses.

The game aims to provide high replayability, competitive leaderboards, and persistent player progression through accounts that save coins, experience, lives, and statistics. By combining fast-paced action with progression mechanics, the project aims to demonstrate a functional indie-style game built using modern web technologies.

**Project Goals**
------------------------
**Primary Goals**
------------------------
Develop a browser-based roguelike shooter

Implement player accounts and saved statistics

Create multiple themed regions and enemies

Implement boss encounters

Provide leaderboards to track high scores

Deliver a playable MVP game experience


**Secondary Goals**
-------------------------------

Add upgrade mechanics

Add shop levels

Improve replayability

Provide polished UI and visual feedback


**Release Plan**
-----------------------------
Sprint	Feature Goals
Sprint 1	Basic mechanics and sprite integration
Sprint 2	Player movement and attacks
Sprint 3	Enemy movement and behavior
Sprint 4	Player and enemy interaction
Sprint 5	Level stages and upgrades
Sprint 6	Playable stages and boss development
Sprint 7	Boss mechanics completed
Sprint 8	Fully playable build
Sprint 9	Shops and random encounters
Sprint 10	Final polish and finishing touches


**Coding Standards**
-------------------------------
The project follows consistent coding practices to ensure readability and maintainability.

**Standards**

Clear and descriptive variable names

Modular code structure

MVC architecture where applicable

Consistent indentation and formatting

Comment complex logic clearly

Avoid duplicate code

**Languages Used
**
GDScript (Godot)

C# (.NET MVC)


**Documentation Standards**
--------------------------------------------
Documentation is maintained to ensure all team members understand the system and development process.

Documentation Includes

Project README overview

Inline code comments for functions and classes

GitHub commit messages describing changes

Design documentation stored in repository

Sprint reports documenting development progress


**Development Environment (Tech Stack)**
-------------------------------------------------------
The project uses the following technologies:

Game Engine

Godot Engine

Backend

.NET 8.0 MVC

Database

SQLite

Development Tools

Visual Studio Community

GitHub

WebGL

Project Management Tools

Trello

GitHub Issues


**Deployment Environment**
-----------------------------------------------
The application is deployed as a web-based game.

Environment

Web browser

WebGL runtime

Hosted web server running .NET MVC

Requirements

Modern browser supporting WebGL

Internet connection


**Version Management**
------------------------------------------------------
Version control is handled using Git and GitHub.

Version Control Practices

Feature branches used for development

Pull requests used for merging code

Code reviews before merging into main branch

Descriptive commit messages


**Test Plan**
--------------------------------------
Testing ensures the game functions correctly across gameplay systems.

Test Types
Unit Testing

Testing individual scripts and functions.

Integration Testing

Testing interactions between systems such as:

Player and enemy interactions

Player and environment interactions

System Testing

Testing the entire game loop including:

Movement

Combat

Score tracking

Level progression

User Testing

Manual playtesting performed by team members.


**Tests Performed**
----------------------------------------------
Test	Description
Player Movement Test	Verify movement input works correctly
Combat System Test	Ensure attacks damage enemies
Collision Detection Test	Verify collisions trigger correct responses
Enemy AI Test	Confirm enemies track and attack the player
Leaderboard Test	Ensure scores save correctly


**Test Analysis**
----------------------------------------------
Testing revealed issues with collision detection, enemy behavior balancing, and player interaction feedback. These issues were addressed through debugging, code improvements, and gameplay adjustments. Continuous playtesting helped refine the gameplay experience and improve overall system stability.


**Test Automation**
----------------------------------------
Automated test coverage is now included for core Godot gameplay systems. A headless regression runner validates stat setup, leveling, buff application, and score manager behavior without opening the editor.

Continuous integration is configured with GitHub Actions to:

Import the Godot project in headless mode

Run the regression test runner on pushes and pull requests

Upload the Godot test log if a workflow run fails

Tests can also be run locally with a Godot 4.6 editor build:

`godot --headless --path Godot/appalachian-trail-game --import`

`godot --headless --path Godot/appalachian-trail-game --script res://tests/test_runner.gd`


**Change Management / Bug Tracking**
----------------------------------------------
Bug tracking and issue management are handled through GitHub Issues and Trello.

Bug Tracking Process

A bug is identified during testing or development.

An issue is created in GitHub.

The issue is assigned to a team member.

The fix is implemented in a development branch.

The code is reviewed and merged.


**Definition of Ready**
-------------------------------------------
A user story is considered Ready when:

The feature is clearly defined.

Acceptance criteria are established.

Required assets or dependencies are available.

The team agrees it can be completed within a sprint.



**Definition of Done**
---------------------------------------------
A feature is considered Done when:

The feature is fully implemented.

The feature works correctly during testing.

Code has been committed to the repository.

Another team member has reviewed the code.

The feature is integrated into the current game build.



**Architectural Design**
------------------------------------------------
[Architectural Design](https://github.com/KJMazely/AppalachianTrail/blob/main/PDFs/Architectual%20Design.png)



**Detailed Design**
--------------------------------------------
Player System

The player character can move using keyboard input and aim using the mouse. The system includes health management, attack mechanics, and score tracking.

Enemy System

Enemies are controlled by AI that allows them to move toward the player and attack. Different enemy types appear depending on the level.

Level System

Each region contains multiple stages with increasing difficulty.

Levels follow a structure:

Easy round (animals)

Medium round (animals and humanoids)

Hard round (humanoids)

Boss round

Boss System
Region	Boss
Mountain	Sasquatch
Desert	Chupacabra
Plains	Jackalope
Snow	Yeti
Forest	Wendigo
Appalachia	Mothman


**Database Design**
------------------------------------------------------
Database system: SQLite

Users Table

Field	| Description
UserID	| Unique player ID
Username	| Player login
Password	| Authentication credential
TotalCoins	| Player currency
XP	| Player experience points
Leaderboard | Table
ScoreID	| Unique score ID
UserID	| Reference to user
Score	| Player score
Date	| Score timestamp


**UI / UX Design**
---------------------------------------------------------
The user interface is designed to be simple, intuitive, and responsive.

Main Screens

Login Screen

Start Menu

Gameplay Screen

Leaderboard

Gameplay HUD Displays

Player health

Score

Coins

Current level


**UX Goals**
------------------------------
  Easy to learn controls

  Clear visual feedback

  Minimal UI clutter

  Fast restarts to encourage replayability
  

**Sprint Reports**
------------------------------
  [Sprint Report 1](https://github.com/KJMazely/AppalachianTrail/blob/main/PDFs/Sprint%20Report%201.pdf)

  [Sprint Report 2](https://github.com/KJMazely/AppalachianTrail/blob/main/PDFs/Spirnt%202.pdf)

  [Sprint Report 3](https://github.com/KJMazely/AppalachianTrail/blob/main/PDFs/Sprint%20Report%203.pdf)

  [Sprint Report 4](https://github.com/KJMazely/AppalachianTrail/blob/main/PDFs/Sprint%20Report%204.pdf)
