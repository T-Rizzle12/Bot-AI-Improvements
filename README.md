# Important:
When this addon receives an update the setting.txt and const.nut will NOT automaticaly add the new cvars to said files, you have two choices either delete the setting.txt and const.nut and let this addon recreate them with the new cvars or use this list of [Addon Settings](https://steamcommunity.com/workshop/filedetails/discussion/2859700506/5002961597086361319/) and manually add the new cvars, if this addon does not detect one of the cvars in the setting.txt it will use this addons default settings as a failsafe.
Also, if you notice certain features are not working, “bots not pulling on their melee weapons when a common infected gets too close,” your setting.txt and/or const.nut may be corrupted or has a typo, you should delete the file and let this addon recreate it. I am working on having this addon automatically fixing said issue.

# Current Features:
-  Bots will pull out their melee weapons when a common infected get to close to them,
-  Improved bot chainsaw behavior, "Bots will shove for two seconds after pulling out their chainsaw and will hold down their attack button when multiple commons are close to them."
-  Bots will crouch when fighting far away common infected, there is a limit to how far away the common infected can be when deciding to crouch
-  Bots with sniper rifles will scope in when crouching to improve their accuracy
-  Attempted to fix bots when incapacitated and sb_allow_shoot_through_survivors is set to 0 not shooting through teammates
- Attemped to fix bots walking though fire, “This bug happens all the time, bots for some reason love trying to reach you by walking straight through Molotovs and/or Gascans, “this is a major problem in expert mode where fire can easily kill you,” what I did to fix this is add a check for active fires and marked the area as blocked for the survivor bots, “infected will still walk into the fire,” making the bots take alternate routes to get to the player.”
- Bots can now attempt to dead stop hunters and jockeys 
- Bots will stop reviving teammates if they are being attacked by a common infected and/or if a tank is nearby, “bots being bots will still attempt to revive teammates, but they will immediately stop the revive if the tank or common infected is too close.”
- Bots will prioritize killing smokers that are trying to grab them
- Bots will not drop melee weapons if they are controlling an idle player
- sb_melee_approach_victim is set based on the distance from the closest player
- Improved bots ability to deal with nearby common infected
- Bots with T1 shotguns and css snipers have a chance to shove after shooting to allow them to shoot faster
- Bots with shotguns will reload for 2 seconds after emptying their weapon clip before firing again
- Bots will reload their secondary weapons if they are not in combat
- Bots will use their secondary weapons if they are attacking far common infected to save ammo

This addon is NOT compatiable with Bot Primary Weapon Enforcer, because of this I have replicated the features of that addon into this one.

If you want more information on the features of this addon here is a link that explains them in a bit more detail [Addon Features Explained](https://steamcommunity.com/workshop/filedetails/discussion/2859700506/5002961597086550851/)

You can customize this addon's cvars, here is a guide on what each cvars does: [Changing Addon Settings](https://steamcommunity.com/workshop/filedetails/discussion/2859700506/5002961597086361319/)

# Todo:
- [x] Fix bots only wanting to pickup melee weapons
- [] Improve bots ability to deal with nearby common infected
- [x] Improve the method that forces bots to press buttons

# Important Discussions:
- [Suggestions](https://steamcommunity.com/workshop/filedetails/discussion/2859700506/6382186451026657878/)
- [Bugs](https://steamcommunity.com/workshop/filedetails/discussion/2859700506/6382186451008463537/)
- [Known Bugs](https://steamcommunity.com/workshop/filedetails/discussion/2859700506/6382186451008413200/)

# Check out my other addons:
- Left 4 Bots Chainsaw Pickup Fix: https://steamcommunity.com/sharedfiles/filedetails/?id=2809813258
- Bot Chatter: https://steamcommunity.com/sharedfiles/filedetails/?id=2857764764
