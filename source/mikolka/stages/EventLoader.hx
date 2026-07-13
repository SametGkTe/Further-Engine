package mikolka.stages;

import mikolka.compatibility.ModsHelper;
import mikolka.vslice.StickerSubState;
import mikolka.compatibility.VsliceOptions;
import mikolka.stages.standard.*;
import mikolka.stages.objects.*;
import mikolka.stages.scripts.*;
import mikolka.stages.erect.*;
import haxe.ds.List;
#if !LEGACY_PSYCH
#if LUA_ALLOWED
import psychlua.FunkinLua;
import mikolka.vslice.components.crash.UserErrorSubstate;
#end
#end

class EventLoader extends BaseStage {
    public static var currentStage:BaseStage = null;
    #if LUA_ALLOWED
    public static function implement(funk:FunkinLua)
        {
            var lua:State = funk.lua;
            funk.set('versionPS', MainMenuState.pSliceVersion.trim());
            Lua_helper.add_callback(lua, "markAsPicoCapable", function(force:Bool = false) {
                new PicoCapableStage(force);
            });
            Lua_helper.add_callback(lua, "changeTransStickers", function(stickerSet:String = null,stickerPack:String = null) {
                if(stickerSet != null && stickerSet != "") StickerSubState.STICKER_SET = stickerSet;
                if(stickerPack != null && stickerPack != "") StickerSubState.STICKER_PACK = stickerPack;
            });
            Lua_helper.add_callback(lua, "getFreeplayCharacter", function() {
                return VsliceOptions.LAST_MOD.char_name;
            });
            Lua_helper.add_callback(lua, "setFreeplayCharacter", function(character:String,modded:Bool = false) {
                VsliceOptions.LAST_MOD = {
                    mod_dir: modded? ModsHelper.getActiveMod() : "",
                    char_name: character
                }; 
            });
        }
    #end
    public static function addstage(name:String) {
        var addNene = true;
        currentStage = null;

        if(VsliceOptions.LEGACY_BAR) new LegacyScoreBars();
        new VSliceEvents();
        if(name == "tank" || name == "tankmanBattlefieldErect") new TankmanStagesAddons();

        currentStage = switch (name)
		{
			case 'stage': new StageWeek1(); 						
			case 'spooky': new Spooky();							
			case 'philly': new Philly();							
			case 'limo': new Limo();								
			case 'mall': new Mall();								
			case 'mallEvil': new MallEvil();						
			case 'school': new School();							
			case 'schoolEvil': new SchoolEvil();					
			case 'tank': new Tank();								
			case 'phillyStreets': new PhillyStreets(); 				
			case 'phillyBlazin': new PhillyBlazin();				
			case 'mainStageErect': new MainStageErect();			
			case 'spookyMansionErect': new SpookyMansionErect();	
			case 'phillyTrainErect': new PhillyTrainErect();  		
			case 'limoRideErect': new LimoRideErect();  			
			case 'mallXmasErect': new MallXmasErect(); 				
			case 'schoolErect': new SchoolErect();					
			case 'schoolPico': new SchoolErect();					
			case 'schoolEvilErect': new SchoolEvilErect();			
			case 'tankmanBattlefieldErect': new TankErect();		
			case 'phillyStreetsErect': new PhillyStreetsErect(); 	
            default: null;
		};
        if(currentStage == null) addNene = false;

        if(addNene && PicoCapableStage.instance == null) {
            var pico = new PicoCapableStage();
            var game = PlayState.instance;
            game.stages.remove(pico);
            game.stages.insert(game.stages.length-2,pico);
        }
        
    } 
}