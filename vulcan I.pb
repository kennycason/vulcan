If InitSprite()
Else
  MessageRequester("Vulcan I","DirectX v.7 or later was unable to be initialized",#MB_ICONERROR)
  End 
EndIf 
If InitKeyboard() 
Else 
  MessageRequester("Vulcan I","A keyboard was unable to be initialized!",#MB_ICONERROR)
  End 
EndIf 

; init joystick at titlescreen (that way user can plug in controller during game play
If InitSound()
  playsound = 1
Else
  MessageRequester("Vulcan I","Sound is unavailable on this computer",#MB_ICONERROR)
  playsound = 0
EndIf
OnErrorResume();  leave this commented Until final product

DefType.l score, highscore

Structure item
  x.w
  y.w
  image.w
EndStructure
NewList item.item()

Structure Explosion
  x.w
  y.w
  explosion.w
  Delay.w
EndStructure
 
NewList explosion.explosion()

Structure enemy           
  x.w
  y.w
  Width.w
  Height.w
  Speedx.w
  Speedy.w
  StartImage.w
  EndImage.w
  ImageDelay.w
  NextImageDelay.w
  ActualImage.w
  Armor.f
  pointvalue.l
  directionx.w
  directiony.w
  weapon.w
  weaponstrength.f
  bspeedx.w
  bspeedy.w
  shotChance.w
  attacktype.w
  misc1.w
  deaddelay.w
  flight.w
EndStructure
NewList enemy.enemy()

Structure Bullet
  x.w
  y.w
  image.w
  SpeedX.w
  SpeedY.w
  weaponstrength.f
  life.w
EndStructure
NewList bullet.Bullet()
NewList enemybullet.Bullet()


;**********************************************************
;
;- AddBullet(Sprite.w, x.w, y.w, SpeedX.w, SpeedY.w, weaponstrength.w, life.w 
;
;**********************************************************
Procedure AddBullet(Sprite, x, y, SpeedX, SpeedY, weaponstrength,life)
  AddElement(Bullet())           
  Bullet()\x      = x
  Bullet()\y      = y
  Bullet()\Image  = Sprite
  Bullet()\SpeedX = SpeedX
  Bullet()\SpeedY = SpeedY
  bullet()\weaponstrength = weaponstrength
  bullet()\life = life
EndProcedure

;**********************************************************
;
;- AddBulletEnemy(Sprite.w, x.w, y.w, SpeedX.w, SpeedY.w, weaponstrength.w 
;
;**********************************************************
Procedure AddBulletEnemy(Sprite, x, y, SpeedX, SpeedY, weaponstrength,type)
  AddElement(enemyBullet())           
  enemyBullet()\x      = x
  enemyBullet()\y      = y
  enemyBullet()\Image  = Sprite
  enemyBullet()\SpeedX = SpeedX
  enemyBullet()\SpeedY = SpeedY
  enemyBullet()\weaponstrength = enemy()\weaponstrength
  enemybullet()\life = type
EndProcedure

;**********************************************************
;
;       BitmapText(Text$, int x, int y)
;
;**********************************************************
Procedure BitmapText(Text$,x,y)
  ; load text A-Z in sprite# 801 - 826 
  ; load num 0-9 in sprite# 827 - 836
  Text$ = UCase(Text$) 
  Length = Len(Text$) 
  For k=1 To Length
    A$ = Mid(Text$, k,1)
    If A$=" "
      x+20 
    Else 
      l = 736+Asc(A$)
      If Asc(A$)<65 Or Asc(A$)>90
        l = 779 +Asc(A$)
      EndIf 
      If IsSprite(l)
        DisplayTransparentSprite(l,x,y)
        x+SpriteWidth(l)
      EndIf 
    EndIf 
  Next 
EndProcedure 

#Max_Enemies = 25
#Max_Bullets = 35
#LevelImage = 500
#Background = 0
#LevelSound = 0
screenX = 800
screenY = 600
;- Openwindow  or screen
If OpenScreen(screenX, screenY, 16, "vulcan I")
;If OpenWindow(0,200,200,screenX,screenY,#PB_Window_SystemMenu | #PB_Window_MinimizeGadget| #PB_Window_MaximizeGadget | #PB_Window_TitleBar | #PB_Window_SizeGadget,"Vulcan")
;OpenWindowedScreen(WindowID(0),0,0,screenX,screenY,1,0,0)  
;window = 1
UseOGGSoundDecoder() 
UseJPEGImageDecoder() 

 file$="sprites\"
 
 k = 801
 For L=65 To 90
   l$ = Chr(L)
   LoadSprite(k,file$+"font\"+l$+".bmp",0)
   k+1
 Next 


 For k=827 To 836
   LoadSprite(k,file$+"font\"+Str(k-827)+".bmp",0)
 Next 
 
 ;*************************************
 LoadSprite(501, file$+"Title.jpg",0)
 LoadSprite(502, file$+"Title2.jpg",0)
 LoadSprite(510, file$+"crosshair.bmp",0)
 LoadSprite(511, file$+"crosshair2.bmp",0)
  For k = 2 To 4
   LoadSound(k, "sound\wav\plasma_"+Str(k-1)+".wav")
 Next

 LoadSound(5, "sound\wav\Explosion_1.wav")
 For k = 6 To 7
   LoadSound(k, "sound\wav\shield_"+Str(k-5)+".wav")
 Next 

  ;LoadSound(1,"sound\wav\weapon_1.wav")
  ;LoadSound(30,"sound\ogg\level_1.ogg")
 DataSection     ; ********* a includebinary file bigger .exe but noone can steal stuff :)
   weapon: IncludeBinary "sound\wav\weapon_1.wav": weapon2:
   bullethit: IncludeBinary "sound\wav\bullethit.wav": bullethit2:
   label: IncludeBinary "sound\ogg\level_1.ogg": label2:
  ; label3: IncludeBinary "sound\wav\intro.mid": label4:
     
 EndDataSection 
 CatchSound(1,?weapon, ?weapon2 - ?weapon) 
  CatchSound(8,?bullethit, ?bullethit2 - ?bullethit) 
 CatchSound(30, ?label, ?label2 - ?label) 
; CatchSound(31, ?label3, ?label4 - ?label3) 


 Gosub DrawTitleScreen
 lvl = 1
 Gosub BetweenLevels
  
  
  
 DataSection
   level1: IncludeBinary "sprites\level\level_1.jpg"
   level2: IncludeBinary "sprites\level\level_2.jpg"
   level3: IncludeBinary "sprites\level\level_3.jpg"
   level4: IncludeBinary "sprites\level\level_4.jpg"
   level5: IncludeBinary "sprites\level\level_5.jpg"
   level6: IncludeBinary "sprites\level\level_6.jpg"
   level7: IncludeBinary "sprites\level\level_7.jpg"
   level8: IncludeBinary "sprites\level\level_8.jpg"
 EndDataSection 
 
 For k=1 To 3
   LoadSprite(k,file$+"ship"+Str(k)+".bmp",0)
 Next
 
 For k=4 To 6
   LoadSprite(k,file$+"ship"+Str(k-3)+"_down.bmp",0)  
 Next 
   
 For k=7 To 9
   LoadSprite(k,file$+"ship"+Str(k-6)+"_up.bmp",0)
 Next   
 
 For k = 495 To 497
   LoadSprite(k,file$+"iship_"+Str(k - 494)+".bmp",0)
 Next 
 
 For k = 498 To 499
   LoadSprite(k,file$+"icon_"+Str(k-497)+".bmp",0)
 Next 

 For k=250 To 255
   LoadSprite(k,file$+"enemy_1_"+Str(k-249)+".bmp",0)
 Next
 
 For k=256 To 261
 LoadSprite(k,file$+"enemy_2_"+Str(k-255)+".bmp",0)
 Next
 
 For k=262 To 268
   LoadSprite(k,file$+"enemy_3_"+Str(k-261)+".bmp",0)
 Next
 
 For k=269 To 271
   LoadSprite(k,file$+"asteriod_1_"+Str(k-268)+".bmp",0)
 Next

 For k=272 To 278
   LoadSprite(k,file$+"enemy_4_"+Str(k-271)+".bmp",0)
 Next
 
 For k=279 To 282
   LoadSprite(k,file$+"enemy_5_"+Str(k-278)+".bmp",0)
 Next
 
 For k=283 To 291
   LoadSprite(k,file$+"enemy_6_"+Str(k-282)+".bmp",0)
 Next
 
 For k = 300 To 301
   LoadSprite(k,file$+"boss_1_"+Str(k-299)+".bmp",0)
 Next 
 
 For k = 302 To 312
   LoadSprite(k,file$+"boss_2_"+Str(k-301)+".bmp",0)
 Next 
 
 For k = 313 To 314
   LoadSprite(k,file$+"boss_3_"+Str(k-312)+".bmp",0)
 Next 

 For k = 315 To 318
   LoadSprite(k,file$+"boss_4_"+Str(k-314)+".bmp",0)
 Next 
 
  For k=319 To 328
   LoadSprite(k,file$+"enemy_7_"+Str(k-318)+".bmp",0)
 Next
 
 For k=10 To 15
   LoadSprite(k,file$+"bullet_"+Str(k-9)+".bmp",0)
 Next 

 For k=16 To 23
   LoadSprite(k,file$+"explosion_"+Str(k-15)+".bmp",0)
 Next

 For k=150 To 155
   LoadSprite(k,file$+"bullet_back_"+Str(k-149)+".bmp",0)
 Next 

 For k=160 To 165
   LoadSprite(k,file$+"bullet_left_"+Str(k-159)+".bmp",0)
 Next
 
 For k=170 To 175
   LoadSprite(k,file$+"bullet_right_"+Str(k-169)+".bmp",0)
 Next 
 
 For k=400 To 407
   LoadSprite(k,file$+"Beam_"+Str(k-399)+".bmp",0)
 Next
 
 For k=480 To 482
   LoadSprite(k,file$+"charging_"+Str(k-479)+".bmp",0)
 Next
 
 For k=422 To 424  
   LoadSprite(k,file$+"Beam_back_"+Str(k-420)+".bmp",0)
 Next
 
 For k=443 To 443  
   LoadSprite(k,file$+"Beam_left_"+Str(k-440)+".bmp",0)
 Next
 
 For k=463 To 463  
   LoadSprite(k,file$+"Beam_right_"+Str(k-460)+".bmp",0)
 Next
 
 For k=200 To 207
   LoadSprite(k,file$+"enemy_bullet_"+Str(k-199)+".bmp",0)
 Next 
 
 For k=25 To 34
   LoadSprite(k,file$+"item_"+Str(k-24)+".bmp",0)
 Next
 
 For k=40 To 42
   LoadSprite(k,file$+"ship"+Str(k-39)+"_forward.bmp",0)
 Next
 ;*****************

  reset = 0
Begin:

  If reset = 1
    reset = 0
    Gosub DrawTitleScreen
  EndIf 
  
  Gosub newgame

  Gosub level

;**********************************************************
;
;- Main Routine
;
;**********************************************************
Main:  
  
  Repeat 
   
    
    TIME = ElapsedMilliseconds()
   
    ;If window = 1
    ;  Event = WindowEvent() 

     ; If Event    
     ;   Delay(10)
    ;  EndIf 
   ; EndIf 
        
      Gosub DrawBackground
     
      Gosub Enemy           ;draws and detects collisions
      
      Gosub Bullet
      
      Gosub Item 
      
      Gosub Misc
       
      Gosub Explosion

      Gosub MovePlayers
      
      If bossexplosion = 0
        Gosub level 
      EndIf 
      
     If boss = 0
       Gosub addenemies
     EndIf 
     
     Gosub DrawMenu
      
     FlipBuffers()
 
     If gameover = 1
      Delay(2000)
      gameover = 0
      Gosub newgame
      Gosub level
    EndIf 

     If selectdelay>0         ; do this here that way the counted decrement even while the button isnt being pushed
       selectdelay - 1
     EndIf 
     If bulletdelay>0
       bulletdelay -1
     EndIf 
     
   If ElapsedMilliseconds() - TIME < 1
     Delay(1)
   EndIf
  
Until KeyboardPushed(#PB_Key_Escape)

Else
 MessageRequester("error","a 800*600, 16 bit screen can not be opened!",#MB_ICONERROR)
End
EndIf 



;**********************************************************
;
;- MovePlayers Routine
;
;**********************************************************

MovePlayers:

  adjustY = 0
  Fire = 0
   
  ExamineKeyboard()
  If joystick = 1
    ExamineJoystick()
  EndIf
  
  playerimage = shield
    
  If KeyboardPushed(#PB_Key_R) Or ( joystick = 1 And JoystickButton(9) )
    FakeReturn 
    Gosub saveHiscore
    reset = 1
    Goto Begin
  EndIf
     
  If KeyboardPushed(#PB_Key_Left) Or (joystick = 1 And JoystickAxisX() = -1 )
    PlayerX-(Abs(levelspeed)+PlayerSpeedX)
     If PlayerX < 0 
      PlayerX = 0  
    EndIf 
  EndIf 
  
  If KeyboardPushed(#PB_Key_Right)  Or (joystick = 1 And JoystickAxisX() = 1 )
    playerimage = shield+39
    PlayerX+PlayerSpeedX
    If PlayerX > 800-PlayerWidth       
      PlayerX = 800-PlayerWidth           
    EndIf
  EndIf 
  
  If KeyboardPushed(#PB_Key_Up) Or (joystick = 1 And JoystickAxisY() = -1 )
    playerimage = shield+6
    If PlayerY < 250 And levelY < 0
        levely + playerSpeedY
        adjustY = playerSpeedY
        If levelY > 0
          levelY = 0
        EndIf 
    Else
        PlayerY-PlayerSpeedY
    EndIf 
  EndIf

    If playerY<0
      playerY = 0
    EndIf  
  
  If KeyboardPushed(#PB_Key_Down) Or (joystick = 1 And JoystickAxisY() = 1 )
    playerimage = shield+3
    If PlayerY > 250 And -levelY  < levelheight -500
        levely - playerSpeedY
        adjustY = -playerSpeedY
        If -levelY > levelheight -500        
          levelY =  -levelheight +500
        EndIf 
    Else
      PlayerY+PlayerSpeedY
    EndIf   
  EndIf 
  
    If playerY>500 - playerheight
      playerY = 500- playerheight
    EndIf   

  If KeyboardPushed(#PB_Key_X) Or (joystick = 1 And JoystickButton(1) )
    Gosub SpeedDown
  EndIf
  
  If KeyboardPushed(#PB_Key_LeftAlt)  Or (joystick = 1 And JoystickButton(7) )  Or (joystick = 1 And JoystickButton(8))
    If charge = 0
      Gosub WeaponCycle
    EndIf 
  EndIf 
  
  If KeyboardPushed(#PB_Key_P)
    lvlup = 1
    levelx = -100000000
    Gosub DeleteEnemies
    Gosub level
  EndIf 
  
  If KeyboardPushed(#PB_Key_I)
    lvlup = 1
    lvl = lastlevel-1
    levelx = -100000000
    Gosub DeleteEnemies
    Gosub level
  EndIf 
  
  If KeyboardPushed(#PB_Key_O)
    beam0 = 1
     beam1 = 1
     beam2 = 1
     beam3 = 1
     beam4 = 1
     special = 2
     weaponselect=15
     weaponstrength = (weaponselect-10)/2 + 1
     weaponspeed = (weaponselect-10)/3 + 16
     weaponsound=0
     shield = 3  ; life
     PlayerImage = 3
     PlayerWidth  = SpriteWidth(PlayerImage)
     PlayerHeight = SpriteHeight(playerImage)
     PlayerSpeedX = 6
     PlayerSpeedY = 7
   EndIf 
  
If DeadDelay = 0
  If BulletDelay = 0
     If KeyboardPushed(#PB_Key_Space) Or (joystick = 1 And JoystickButton(3) )
        Gosub Shoot
     EndIf 
  EndIf  

EndIf 



If charge = 1
  If KeyboardPushed(#PB_Key_Space)
    Gosub Charging
  ElseIf joystick = 1
    If JoystickButton(3)
      Gosub Charging
      joystickreleased = 0
    Else
      joystickreleased = 1 
    EndIf  
  EndIf 
  
                
  If KeyboardReleased(#PB_Key_Space) 
    Gosub ReleaseCharge
  ElseIf joystick = 1
    If Joystickreleased = 1
      Gosub ReleaseCharge
    EndIf
  EndIf 
EndIf 

  If joystick = 1
    If JoystickButton(10)
      paused = 1
      pausecounter = 20
      Gosub DrawMenu
      BitmapText("PAUSE",320,280)
      FlipBuffers()
    EndIf
    Repeat
      If joystick = 1
        ExamineJoystick()
      EndIf
      If pausecounter < 0 
        If joystick = 1
          If JoystickButton(1) Or JoystickButton(2) Or JoystickButton(3) Or JoystickButton(4) Or JoystickButton(5) Or JoystickButton(6) Or JoystickButton(7) Or JoystickButton(8)
            paused = 0
            pausecounter = 20
          EndIf
       EndIf 
      Else
        pausecounter - 1
      EndIf 
    Until paused = 0
  EndIf   

  Repeat 
    ExamineKeyboard()
    If KeyboardReleased(#PB_Key_C) ;pause
      If Paused = 0
        Gosub DrawMenu
        BitmapText("PAUSE",320,280)
        FlipBuffers()
        Paused = 1
      Else 
        Paused = 0
      EndIf 
    EndIf 
      
  Until paused = 0

Return




;**********************************************************
;
;- Enemy Routine
;
;**********************************************************
Enemy:  

ResetList(enemy())
While NextElement(enemy())
  DisplayTransparentSprite(enemy()\ActualImage, enemy()\x, enemy()\y) 
    ; move
If enemy()\flight = 1
  If enemy()\directiony = 1  ; plain
    enemy()\y + enemy()\speedy + adjustY
  Else
    enemy()\y - enemy()\speedy + adjustY
  EndIf 
   
  If enemy()\directionx = 1
    enemy()\x + enemy()\Speedx 
  Else
    enemy()\x - enemy()\Speedx 
  EndIf 
  
ElseIf enemy()\flight = 2 ; swoop
   y = (enemy()\y - playerY)/Sqr(Pow((enemy()\y - playerY),2) + Pow((enemy()\X - playerX),2))  ; :P never thought id use vectors..
   x = (enemy()\X - playerX)/Sqr(Pow((enemy()\y - playerY),2) + Pow((enemy()\X - playerX),2))  
   x+(enemy()\x - playerX)/(14)
   y+(enemy()\y - playerY)/(14)
   If x>10
     x = enemy()\speedx*3
   EndIf
   If y > 10 
     y = enemy()\speedy*3
   EndIf
   If Abs((enemy()\y - playerY)) >30 And Abs((enemy()\X - playerX))>30
     enemy()\y - y + adjustY
     enemy()\x - x + adjustX
   Else
     enemy()\flight = 1
   EndIf 
ElseIf enemy()\flight = 3
  
EndIf 

 
    If (enemy()\directiony = 1 And SpritePixelCollision(#LevelImage,levelx,levely, enemy()\ActualImage, enemy()\x , enemy()\y + 8)) Or (enemy()\y >= levelheight  + levely - enemy()\height  )
      enemy()\directiony = 0
    ElseIf (enemy()\directiony = 0 And SpritePixelCollision(#LevelImage,levelx,levely, enemy()\ActualImage, enemy()\x , enemy()\y -5)) Or ( enemy()\y  < levely )
      enemy()\directiony = 1
    EndIf 
    If enemy()\directionx = 1 And SpritePixelCollision(#LevelImage,levelx,levely, enemy()\ActualImage, enemy()\x + 8, enemy()\y)
      enemy()\directionx = 0
    ElseIf enemy()\directionx = 0 And SpritePixelCollision(#LevelImage,levelx,levely, enemy()\ActualImage, enemy()\x-5 , enemy()\y )
      enemy()\directionx = 1
    EndIf 
   
  If enemy()\NextImageDelay = 0
    enemy()\ActualImage+1
    If enemy()\ActualImage > enemy()\EndImage
      enemy()\ActualImage = enemy()\StartImage
    EndIf

    enemy()\NextImageDelay = enemy()\ImageDelay
  Else
    enemy()\NextImageDelay - 1
  EndIf


  If Random(1000) < enemy()\shotChance And CountList(enemyBullet()) < #Max_bullets
    If enemy()\attacktype = 0
      addBulletEnemy(enemy()\weapon, enemy()\x , enemy()\y+32, enemy()\bSpeedX, enemy()\bSpeedY, enemy()\weaponstrength , enemy()\misc1)
    ElseIf enemy()\attacktype = 1
      y = (playerY - enemy()\y)/Sqr(Pow((enemy()\y - playerY),2) + Pow((enemy()\X - playerX),2))  ; :P never thought id use vectors..
      x = ( playerX - enemy()\x)/Sqr(Pow((enemy()\y - playerY),2) + Pow((enemy()\X - playerX),2))  
      x+(playerX - enemy()\x )/enemy()\bspeedx
      y+(playerY - enemy()\y )/enemy()\bspeedy
      addBulletEnemy(enemy()\weapon, enemy()\x , enemy()\y, x, y, enemy()\weaponstrength, enemy()\misc1 )
    ElseIf enemy()\attacktype = 2
      For k = 0 To Random(mode*2)
        addBulletEnemy(enemy()\weapon, enemy()\x , enemy()\y, enemy()\bSpeedX-Random(5), enemy()\bSpeedY+Random(enemy()\bSpeedY+2), enemy()\weaponstrength , enemy()\misc1)
        addBulletEnemy(enemy()\weapon, enemy()\x , enemy()\y, enemy()\bSpeedX-Random(5), -enemy()\bSpeedY-Random(enemy()\bSpeedY+2), enemy()\weaponstrength , enemy()\misc1)
      Next 
    EndIf
  EndIf 

    
  If deaddelay = 0
    If enemy()\deaddelay < 1
    ResetList(Bullet())
    While NextElement(Bullet())
        If enemy()\x < 790 ;give the enemies a chance.. 
          If SpritePixelCollision(Bullet()\Image, Bullet()\x, Bullet()\y, enemy()\ActualImage, enemy()\x, enemy()\y)
            hit+1
            PlaySound(2,0)
            enemy()\Armor-Bullet()\weaponstrength
            If boss = 0
              enemy()\deaddelay= 20
            Else
              enemy()\deaddelay = 0
            EndIf 
            ; play a sound
            If bullet()\image < 403
              DeleteElement(Bullet())
            ElseIf bullet()\image >= 403 And boss = 1
              DeleteElement(bullet())
            EndIf
          EndIf
        EndIf  
    Wend  
      Else
        enemy()\deaddelay - 1
      EndIf  
  
  
    If SpritePixelCollision(PlayerImage, PlayerX, PlayerY, enemy()\ActualImage, enemy()\x, enemy()\y)
    shield - 1
      If shield < 1
        Goto dead
      EndIf 
      If playsound = 1     
        PlaySound(5,0)
      EndIf 
      playerimage = shield
    EndIf
  EndIf 
   
  
  If enemy()\Armor <= 0
    Score+enemy()\pointvalue
    enemykill + 1
    Gosub makeitems
 
      If  enemy()\misc1 = 1        ; misc1 is pretty much acting as, is the image a boss?
        For k = 0 To 30
          AddElement(Explosion())
          Explosion()\x = enemy()\x-50 + Random(100)
          Explosion()\y = enemy()\y-50 + Random(100)
        Next
         
        DeleteElement(enemy(),1)
        ResetList(enemy())
         If NextElement(enemy())  ; supportive of multiple boss enemys
         Else 
           enemykill + 1
           levelx = -500000; for purpuse of gosub level, reset to lvllength
           levellength = 0
           lvlup = 1
           bossexplosion = 1
           Gosub explosion 
         EndIf 
      Else 
        AddElement(Explosion())
        Explosion()\x = enemy()\x-50 + Random(100)
        Explosion()\y = enemy()\y-50 + Random(100)
        DeleteElement(enemy())
      EndIf 
 
 
  ElseIf  (enemy()\x < -enemy()\width  Or enemy()\x > 1050 Or SpritePixelCollision(#LevelImage,levelx,levely, enemy()\ActualImage, enemy()\x , enemy()\y)) And boss = 0 ; this is only here to consolidate the deleteelement(enemy()) commands
    DeleteElement(enemy())
  ElseIf enemy()\x > 800-enemy()\width And boss = 1
    enemy()\directionx= 0
  ElseIf enemy()\x < 50 And boss = 1
    enemy()\directionx= 1
  EndIf 
Wend


  ResetList(enemyBullet())
  While NextElement(enemyBullet())
    
    If SpritePixelCollision(#LevelImage, levelx, levely , enemyBullet()\image, enemyBullet()\x, enemyBullet()\y) And boss = 0
      If boss = 0
        DeleteElement(enemybullet())
      ElseIf enemybullet()\life = 1
        enemyBullet()\SpeedY = 0
        enemyBullet()\SpeedX = 0
      EndIf 
    ElseIf enemyBullet()\y < levely  Or enemyBullet()\x < -20 Or enemyBullet()\x > 800 Or enemyBullet()\y > levelheight + levely - playerheight   
      DeleteElement(enemyBullet())
    Else 
      
      enemyBullet()\x + enemyBullet()\SpeedX
      enemyBullet()\y + enemyBullet()\SpeedY +adjustY
      DisplayTransparentSprite(enemyBullet()\Image, enemyBullet()\x, enemyBullet()\y)
      If deaddelay = 0
        If SpritePixelCollision(PlayerImage, PlayerX, PlayerY, enemyBullet()\image, enemyBullet()\x, enemyBullet()\y)       
          shield - enemyBullet()\weaponstrength
          playerimage = shield
          DeleteElement(enemyBullet())
          If shield < 1          
            Goto dead
          EndIf 
          ; play a sound
        EndIf 
      EndIf
    EndIf
  Wend 
  
  
Return 



;**********************************************************
;
;- Bullet Routine
;
;**********************************************************

Bullet:
  ResetList(Bullet())
  While NextElement(Bullet()) 
    If SpritePixelCollision(#LevelImage, levelx, levely, Bullet()\image, Bullet()\x, Bullet()\y)
      If bullet()\life  < 1
        If deadDelay < 1
          miss+1
        EndIf 
        DeleteElement(bullet()) 
      Else
        bullet()\life-1
        If boss = 1
          If deadDelay < 1
            miss+1
          EndIf 
          DeleteElement(bullet())
          Break 
        EndIf 
        Bullet()\x + Bullet()\SpeedX
        Bullet()\y + Bullet()\SpeedY + adjustY
        DisplayTransparentSprite(Bullet()\Image, Bullet()\x, Bullet()\y)
      EndIf 
    ElseIf Bullet()\y < levely-60 Or Bullet()\x < -100  Or Bullet()\x > 800+60 Or Bullet()\y  > levelheight + levely - playerheight
        If deadDelay < 1
          miss+1
        EndIf 
      DeleteElement(Bullet())
    Else
      Bullet()\x + Bullet()\SpeedX
      Bullet()\y + Bullet()\SpeedY + adjustY
      DisplayTransparentSprite(Bullet()\Image, Bullet()\x, Bullet()\y) 
    EndIf
  Wend


Return 





;**********************************************************
;
;- Item Routine
;
;**********************************************************
Item:


  ResetList(item())
  While NextElement(item())
    DisplayTransparentSprite(item()\Image, item()\x, item()\y)
    item()\x+levelspeed
    item()\y + adjustY
    If item()\x<-50
      DeleteElement(item())
    ElseIf SpriteCollision(playerimage, playerX, playerY,item()\image,item()\x,item()\y)
        If item()\image=25 ; score
          score+500
        ElseIf item()\image=26 ;weaponup
          score + 50
          weaponselect+1
          If weaponselect <15
            weaponstrength = (weaponselect-10)/2 + 1
            weaponspeed = (weaponselect-10)/3 + 16
            weaponsound=0
          ElseIf weaponselect>15
            weaponselect=15
          EndIf 
        ElseIf item()\image=27   ; homing
          score+150
          beam1 = 1           
        ElseIf item()\image=32  ; laser
          score+150
          beam2 = 1           ;
        ElseIf item()\image=33  ; charge
          score+150        
          beam4 = 1           
        ElseIf item()\image=34  ; vulcan
          score+150        
          beam3 = 1                  
        ElseIf item()\image=28  ; lives
          score+150        
          lives+1
        ElseIf item()\image=29  ; special
          score+200        
          special+1 
          If special>2
            special = 2
          EndIf  
          If playsound = 1
            PlaySound(7)
          EndIf 
        ElseIf item()\image=30  ; shield
          score+150        
          shield+1
          If shield>3
            shield = 3
          EndIf 
          If playsound = 1
            PlaySound(6)
          EndIf 
          playerimage = shield
        ElseIf item()\image=31  ; speed
          score+50        
          playerspeedx+1
          playerspeedy+1
          If playerspeedx>7
            playerspeedx = 7
          EndIf
          If playerspeedy>7
            playerspeedy = 7
          EndIf         
        EndIf
        DeleteElement(item()) 
    EndIf
  Wend


 
Return   



;**********************************************************
;
;- Misc Routine
;
;**********************************************************


Misc:



 If Dead = 0
    flash = 1-flash
     If DeadDelay>0
      DeadDelay-1
      If flash = 1
        If DeadDelay < 300
          DisplayTransparentSprite(PlayerImage, PlayerX, PlayerY)
        EndIf
      EndIf
    Else
      DisplayTransparentSprite(PlayerImage, PlayerX, PlayerY)
    EndIf
  Else
    Dead = 0
  EndIf

  


  levelx+levelspeed

  If deaddelay = 0
    If SpritePixelCollision(PlayerImage, PlayerX, PlayerY, #LevelImage, levelx, levely)                 
        Goto dead
        If playsound = 1     
          PlaySound(5,0)
        EndIf 
      playerimage = shield
    EndIf 
  EndIf


  DisplayTransparentSprite(#LevelImage, levelx, levely)
  



Return  
 
 


;**********************************************************
;
;- MakeItems Routine
;
;**********************************************************
MakeItems:

If Random(itemfrequency)<10
  AddElement(item())
  
    item()\x = enemy()\x
    item()\y = enemy()\y
    item= Random(30)
    If item>= 19
      item()\image = 25  ;points
    ElseIf item >=14 And item <=18
      item()\image = 31  ; speedup
    ElseIf item >=11 And item <=13
      item()\image = 26  ; weaponselect up
    ElseIf item>=6 And item <=10
      b = Random(20)
      If b<7   ; <7
        item()\image = 27 ; homing 
      ElseIf b >=7 And b <14
        item()\image = 32  ; laser  
      ElseIf b >=14 And b <19
        item()\image = 33  ; charge
      ElseIf b >= 19
        item()\image = 34  ; vulcan
      EndIf   
    ElseIf item = 5   
      item()\image = 25  ;life ********************* make this the force shield later
    ElseIf item = 4        
      item()\image = 28  ;life
    ElseIf item = 3
      item()\image = 29   ;special
    ElseIf item <=2
      item()\image = 30   ;shield
    EndIf
EndIf 

Return


;**********************************************************
;
;- addEnemies Routine
;
;**********************************************************
addEnemies:
If CountList(enemy()) < #Max_enemies
If enemyDelay <= 0 


  If enemyset = 1  
    enemy = 1
  ElseIf enemyset = 2
    If Random(100) > frequency1
      enemy = 1
    Else 
      enemy = 2
    EndIf
  ElseIf enemyset = 3
    k = Random(100)
    If k < frequency1
      enemy = 1
    ElseIf k >= frequency1 And k <= frequency2
      enemy = 2
    Else
      enemy = 3
    EndIf
  EndIf 
  
 Ey1 = Random(levelHeight) - 100
 temp = 0
  howM = Random(howMany)+1
  For k = 1 To howM
    If k > howM
      Break
    EndIf 
    AddElement(enemy()) 
    If enemy = 1
        enemy()\StartImage  = EStartImage1
        enemy()\EndImage    = EEndImage1
        enemy()\ActualImage = EActualImage1
        enemy()\attacktype =  Eattacktype1 
        enemy()\bspeedx = Ebspeedx1
        enemy()\bspeedy = Ebspeedy1
        enemy()\speedX = EspeedX1
        enemy()\speedY = Espeedy1
        enemy()\DirectionY = EdirectionY1
        enemy()\shotchance = Eshotchance1
        enemy()\Armor = EArmor1
        enemy()\pointvalue = Epointvalue1
        enemy()\weapon = Eweapon1
        enemy()\weaponstrength = Eweaponstrength1 
        enemy()\flight = Eflight1
        enemy()\misc1 = Emisc1
    ElseIf enemy = 2
        enemy()\StartImage  = EStartImage2
        enemy()\EndImage    = EEndImage2
        enemy()\ActualImage = EActualImage2
        enemy()\attacktype =  Eattacktype2 
        enemy()\bspeedx = Ebspeedx2
        enemy()\bspeedy = Ebspeedy2
        enemy()\speedX = EspeedX2
        enemy()\speedY = Espeedy2
        enemy()\DirectionY = EdirectionY2
        enemy()\shotchance = Eshotchance2
        enemy()\Armor = EArmor2
        enemy()\pointvalue = Epointvalue2
        enemy()\weapon = Eweapon2
        enemy()\weaponstrength = Eweaponstrength2
        enemy()\flight = Eflight2
        enemy()\misc1 = Emisc2
    ElseIf enemy = 3
        enemy()\StartImage  = EStartImage3
        enemy()\EndImage    = EEndImage3
        enemy()\ActualImage = EActualImage3
        enemy()\attacktype =  Eattacktype3 
        enemy()\bspeedx = Ebspeedx3
        enemy()\bspeedy = Ebspeedy3
        enemy()\speedX = EspeedX3
        enemy()\speedY = Espeedy3
        enemy()\DirectionY = EdirectionY3
        enemy()\shotchance = Eshotchance3
        enemy()\Armor = EArmor3
        enemy()\pointvalue = Epointvalue3
        enemy()\weapon = Eweapon3
        enemy()\weaponstrength = Eweaponstrength3 
        enemy()\flight = Eflight3
        enemy()\misc1 = Emisc1
    EndIf     
      enemy()\Width  = SpriteWidth(enemy()\StartImage)
      enemy()\Height = SpriteHeight(enemy()\StartImage)
      enemy()\x = ScreenX+enemy()\width+temp
      enemy()\y = Ey1
      enemy()\ImageDelay  =  EImageDelay
      enemy()\NextImageDelay = ENextImageDelay
      enemy()\DirectionX = 0
      enemy()\deaddelay = Edeaddelay
      enemyDelay = Random(lvldifficulty) 
      enemy()\shotchance + 3*(mode-1)
      If enemy()\armor > 1000
        Break
      Else
        temp+enemy()\Width + 10
      EndIf 

     If SpritePixelCollision(enemy()\ActualImage,enemy()\x,enemy()\y,#LevelImage,levelx,levely) Or enemy()\y > levelHeight
       DeleteElement(enemy())
       Break 
     EndIf 

  Next 


  
  
Else
  enemyDelay-1
EndIf 
EndIf 
Return



;**********************************************************
;
;- AddBoss Routine
;
;**********************************************************

AddBoss:

  AddElement(enemy())
      enemy()\Width  = SpriteWidth(EStartImage1) 
      enemy()\Height = SpriteHeight(EStartImage1)
      enemy()\x = Ex1
      enemy()\y = Ey1
      enemy()\Speedx  = Espeedx1
      enemy()\Speedy  = Espeedy1
      enemy()\StartImage  = EStartImage1
      enemy()\EndImage    = EEndImage1
      enemy()\ImageDelay  =  EImageDelay1
      enemy()\NextImageDelay = ENextImageDelay1
      enemy()\ActualImage = EActualImage1
      enemy()\Armor = EArmor1
      enemy()\PointValue = EPointValue1
      enemy()\DirectionX = EDirectionX1
      enemy()\DirectionY = EDirectionY1
      enemy()\weapon = Eweapon1
      enemy()\weaponstrength = EWeaponStrength1
      enemy()\bspeedx = Ebspeedx1
      enemy()\bspeedy = Ebspeedy1
      enemy()\shotChance = Eshotchance1
      enemy()\attacktype = Eattacktype1
      enemy()\misc1 = Emisc1
      enemy()\deaddelay = Edeaddelay1
      enemy()\flight = Eflight1
Return 



;**********************************************************
;
;- Level Routine
;
;**********************************************************

level:
   
If levelx < -levellength +screenX And boss = 0  ; level stops at end of screen
  do = 1
ElseIf  levelx < -levellength - screenX And lvlup = 1; level fully past
  do = 1
  lvlup = 0
EndIf 

If do = 1

  If boss = 0
     boss = 1
  Else 
    boss = 0
    lvl+1
    If lvl = lastLevel+2 And bonusLevel = 1
      bonusLevel = 0
      lvl = 8
    ElseIf lvl = lastLevel+2
      lvl = 1
    ElseIf lvl = lastLevel + 1 
        Gosub BeatGame
    Else 
      Gosub BetweenLevels
      Gosub DeleteEnemyBullets
    EndIf 
  EndIf 

  If lvl = 1 And boss = 0
    backgroundmap = 2
    backgroundspeedx=-4
    backgroundspeedy=0
    levely = 0
    lvlsound = 30
    levelspeed = -3

    itemfrequency = 70 ; if random(itemfrequency) < 10
    lvldifficulty = 220
    howMany = 3
    
    EStartImage1  = 250
    EEndImage1    = 255
    EActualImage1 = 250
    Eattacktype1 = 0  
    Ebspeedx1 = -5
    Ebspeedy1 = 0     ; reqular
    EspeedX1 = 3
    EspeedY1 = 3
    Eweapon1 = 200
    Eshotchance1 = 9
    EArmor1 = 1
    Epointvalue1 = 40
    Eweaponstrength1 = 1
    Eflight1 = 1
   
    enemyset = 1
    
    Emisc1 = 0

    EImageDelay  =  4   
    ENextImageDelay = EImageDelay
    Edeaddelay = 20
    
  ElseIf lvl =1 And boss = 1
    Gosub DeleteEnemies
    backgroundspeedx=0
    backgroundspeedy=0
    levelspeed = 0
    itemfrequency = 0 
    
  For k = 1 To 3
    Eshotchance1 = 20
    Ex1 = screeny-150-Random(200)
    Ey1 = 300+ Random(50)
    ESpeedx1 = 2
    Espeedy1 = 2
    EStartImage1  = 302
    EEndImage1    = 312
    EImageDelay1  =  6
    ENextImageDelay1 = EImageDelay
    EActualImage1 = 302
    EArmor1 = 15
    Epointvalue1 = 5000
    Edirectionx1 = Random(1)
    Edirectiony1 = Random(1)
    Eweapon1 = 203
    Eweaponstrength1 = 1
    Ebspeedx1 = 150
    Ebspeedy1 = 150
    Eattacktype1 = 1
    Emisc1 = 1
    Eflight1 = 1
    Edeaddelay = 5
    Gosub AddBoss
  Next  
  
  ElseIf lvl = 2 And boss = 0
    backgroundmap = 2
    backgroundspeedx=-4
    backgroundspeedy=0
    levely = 0
    lvlsound = 30
    levelspeed = -3

    itemfrequency = 70 ; if random(itemfrequency) < 10
    lvldifficulty = 220
    howMany = 4
    
    EStartImage1  = 256
    EEndImage1    = 261
    EActualImage1 = 256
    Eattacktype1 = 0  
    Ebspeedx1 = -5
    Ebspeedy1 = 0     ; reqular
    EspeedX1 = 3
    EspeedY1 = 3
    Eweapon1 = 200
    Eshotchance1 = 9
    EArmor1 = 1
    Epointvalue1 = 40
    Eweaponstrength1 = 1
    Eflight1 = 1
   
    enemyset = 1
    
    Emisc1 = 0

    EImageDelay  =  4   
    ENextImageDelay = EImageDelay
    Edeaddelay = 20
    
  ElseIf lvl =2 And boss = 1
    Gosub DeleteEnemies
    backgroundspeedx=0
    backgroundspeedy=0
    levelspeed = 0
    itemfrequency = 0 
    
  For k = 1 To 3
    Eshotchance1 = 20
    Ex1 = screeny-150-Random(200)
    Ey1 = 300+ Random(50)
    ESpeedx1 = 2
    Espeedy1 = 2
    EStartImage1  = 302
    EEndImage1    = 312
    EImageDelay1  =  6
    ENextImageDelay1 = EImageDelay
    EActualImage1 = 302
    EArmor1 = 15
    Epointvalue1 = 5000
    Edirectionx1 = Random(1)
    Edirectiony1 = Random(1)
    Eweapon1 = 203
    Eweaponstrength1 = 1
    Ebspeedx1 = 150
    Ebspeedy1 = 150
    Eattacktype1 = 1
    Emisc1 = 1
    Eflight1 = 1
    Edeaddelay = 5
    Gosub AddBoss
  Next 

     
  ElseIf lvl = 3 And boss = 0
    backgroundmap = 2
    backgroundspeedx=-4
    backgroundspeedy=0
    levely = 0
    lvlsound = 30
    levelspeed = -3

    itemfrequency = 70 ; if random(itemfrequency) < 10
    lvldifficulty=150
    howMany = 5
    
    EStartImage1  = 269
    EEndImage1    = 269
    EActualImage1 = 269
    Eattacktype1 = 1000  ; no shot
    Ebspeedx1 = -5
    Ebspeedy1 = 0     ; reqular
    EspeedX1 = 3
    EspeedY1 = 0
    Eweapon1 = 200
    Eshotchance1 = 10
    EArmor1 = 2000
    Epointvalue1 = 3000
    Eweaponstrength1 = 0
    Eflight1 = 1
    
    EStartImage2  = 270
    EEndImage2    = 270
    EActualImage2 = 270
    Eattacktype2 = 100    
    Ebspeedx2 = -5
    Ebspeedy2 = 0
    EspeedX2 = 3
    EspeedY2 = 0
    Eweapon2 = 200
    Eshotchance2 = 10
    EArmor2 = 2000
    Epointvalue2 = 3000
    Eweaponstrength2 = 0
    Eflight2 = 1
    
    EStartImage3  = 272
    EEndImage3    = 278
    EActualImage3 = 272
    Eattacktype3 = 0   
    Ebspeedx3 = -4
    Ebspeedy3 = 0
    EspeedX3 = 2
    EspeedY3 = 2
    Eweapon3 = 200
    Eshotchance3 = 3
    EArmor3 = 1
    Epointvalue3 = 30
    Eweaponstrength3 = 1
    Eflight3 = 2  

    frequency1 = 10
    frequency2 = 50
    enemyset = 3
    
    Emisc1 = 0

    EImageDelay  =  4   
    ENextImageDelay = EImageDelay
    Edeaddelay = 20
    
  ElseIf lvl =3 And boss = 1
    Gosub DeleteEnemies
    levelspeed = 0
    itemfrequency = 0
    Eshotchance1 = 40
    Ex1 = screenx-300
    Ey1 = 100
    ESpeedx1 = 2
    Espeedy1 = 3
    EStartImage1  = 300
    EEndImage1    = 301
    EImageDelay1  =  2
    ENextImageDelay1 = EImageDelay
    EActualImage1 = 300
    EArmor1 = 40
    Epointvalue1 = 5000
    Edirectionx1 = 0
    Edirectiony1 = Random(1)
    Eweapon1 = 202
    Eweaponstrength1 = 1
    Ebspeedx1 = -5
    Ebspeedy1 = 0 
    Eattacktype1 = 0
    Emisc1 = 1
    Eflight1 = 1
    
    Edeaddelay = 5
    Gosub AddBoss
  ElseIf lvl = 4 And boss = 0
    
    levely = 0
    backgroundmap = 5
    backgroundspeedx=-1
    backgroundspeedy=0
    lvlsound = 30
    levelspeed = -3
    howMany = 0

    itemfrequency = 70  ; if random(itemfrequency) < 10
    lvldifficulty=200   ; enemy percentage
    
    EStartImage1  = 256
    EEndImage1    = 261
    EActualImage1 = 256
    Eattacktype1 = 1 ; homing
    Ebspeedx1 = 100
    Ebspeedy1 = 100  
    EspeedX1 = 2
    EspeedY1 = 2
    Eweapon1 = 200
    Eshotchance1 = 6     ; if rand(1000) < EshotChance
    EArmor1 = 1
    Epointvalue1 = 40
    Eweaponstrength1 = 1
    Emisc1 = 0
    Eflight1 = 2  

    enemyset = 1
    
    EImageDelay  =  4   
    ENextImageDelay = EImageDelay
    Edeaddelay = 20

  ElseIf lvl =4 And boss = 1
     
    Gosub DeleteEnemies
    levelspeed = 0
    itemfrequency = 0
    
    Eshotchance1 = 70
    Ex1 = screenx-400
    Ey1 = 300
    ESpeedx1 = 0
    Espeedy1 = 2
    EStartImage1  = 300
    EEndImage1    = 301
    EImageDelay1  =  2
    ENextImageDelay1 = EImageDelay
    EActualImage1 = 300
    EArmor1 = 40
    Epointvalue1 = 5000
    Edirectionx1 = 0
    Edirectiony1 = 0
    Eweapon1 = 202
    Eweaponstrength1 = 1
    Ebspeedx1 = -5
    Ebspeedy1 = 0 
    Eattacktype1 = 0
    Emisc1 = 1
    Eflight1 = 1
    
    Edeaddelay = 5
    Gosub AddBoss
   
    
  ElseIf lvl =5 And boss = 0

    backgroundmap = 2
    backgroundspeedx=-4
    backgroundspeedy=0
    levely = 0
    lvlsound = 30
    levelspeed = -3

    itemfrequency = 70 ; if random(itemfrequency) < 10
    lvldifficulty = 280
    howMany = 0
    
    EStartImage1  = 302
    EEndImage1    = 312
    EActualImage1 = 302
    Eattacktype1 = 1
    Ebspeedx1 = 130
    Ebspeedy1 = 130     ; reqular
    EspeedX1 = 3
    EspeedY1 = 3
    Eweapon1 = 203
    Eshotchance1 = 8
    EArmor1 = 2
    Epointvalue1 = 40
    Eweaponstrength1 = 1
    Eflight1 = 1
   
    enemyset = 1
    
    Emisc1 = 0

    EImageDelay  =  4   
    ENextImageDelay = EImageDelay
    Edeaddelay = 20
    
    
  ElseIf lvl =5 And boss = 1
    Gosub DeleteEnemies
    backgroundspeedx=0
    backgroundspeedy=0
    levelspeed = 0
    itemfrequency = 0 
    
  For k = 1 To 3
    Eshotchance1 = 20
    Ex1 = screeny-150-Random(200)
    Ey1 = 300+ Random(50)
    ESpeedx1 = 2
    Espeedy1 = 2
    EStartImage1  = 302
    EEndImage1    = 312
    EImageDelay1  =  6
    ENextImageDelay1 = EImageDelay
    EActualImage1 = 302
    EArmor1 = 15
    Epointvalue1 = 5000
    Edirectionx1 = Random(1)
    Edirectiony1 = Random(1)
    Eweapon1 = 203
    Eweaponstrength1 = 1
    Ebspeedx1 = 150
    Ebspeedy1 = 150
    Eattacktype1 = 1
    Emisc1 = 1
    Eflight1 = 1
    Edeaddelay = 5
    Gosub AddBoss
  Next  

  ElseIf lvl =6 And boss = 0
    playerSpeedX = 6
    playerSpeedY = 6
    backgroundmap = 2
    backgroundspeedx=-20
    backgroundspeedy=0
    levely = 0
    lvlsound = 30
    levelspeed = -10

    itemfrequency = 40 ; if random(itemfrequency) < 10
    lvldifficulty = 99999
    howMany = 2
    
    EStartImage1  = 250
    EEndImage1    = 255
    EActualImage1 = 250
    Eattacktype1 = 0  
    Ebspeedx1 = -5
    Ebspeedy1 = 0     ; reqular
    EspeedX1 = 3
    EspeedY1 = 3
    Eweapon1 = 201
    Eshotchance1 = 0
    EArmor1 = 1
    Epointvalue1 = 1000
    Eweaponstrength1 = 1
    Eflight1 = 1
    
    enemyset = 1
    
    Emisc1 = 0

    EImageDelay  =  4   
    ENextImageDelay = EImageDelay
    Edeaddelay = 20
    
  ElseIf lvl =6 And boss = 1
    Gosub DeleteEnemies
    backgroundspeedx=-20
    backgroundspeedy=0
    levelspeed = 0
    itemfrequency = 0 
    
    Eshotchance1 = 13
    Ex1 = 420
    Ey1 = 230+levelY
    ESpeedx1 = 1
    Espeedy1 = 0
    EStartImage1  = 315
    EEndImage1    = 318
    EImageDelay1  =  20
    ENextImageDelay1 = EImageDelay
    EActualImage1 = 315
    EArmor1 = 55
    Epointvalue1 = 10000
    Edirectionx1 = Random(1)
    Edirectiony1 = Random(1)
    Eweapon1 = 205
    Eweaponstrength1 = 1
    Ebspeedx1 = 90
    Ebspeedy1 = 90
    Eattacktype1 = 1
    Emisc1 = 1
    Eflight1 = 1
    Edeaddelay = 5
    Gosub AddBoss
 
  ElseIf lvl =7 And boss = 0
    backgroundmap = 2
    backgroundspeedx=-4
    backgroundspeedy=0
    levely = 0
    lvlsound = 30
    levelspeed = -3

    itemfrequency = 40 ; if random(itemfrequency) < 10
    lvldifficulty = 200
    howMany = 2
    
    EStartImage1  = 319
    EEndImage1    = 328
    EActualImage1 = 319
    Eattacktype1 = 0  
    Ebspeedx1 = -5
    Ebspeedy1 = 0     ; reqular
    EspeedX1 = 3
    EspeedY1 = 3
    Eweapon1 = 204
    Eshotchance1 = 9
    EArmor1 = 1
    Epointvalue1 = 40
    Eweaponstrength1 = 1
    Eflight1 = 1
    
    enemyset = 1
    
    Emisc1 = 0

    EImageDelay  =  4   
    ENextImageDelay = EImageDelay
    Edeaddelay = 20
    
  ElseIf lvl =7 And boss = 1
    Gosub DeleteEnemies
    backgroundspeedx=-4
    backgroundspeedy=0
    levelspeed = 0
    itemfrequency = 0 
    
    Eshotchance1 = 12
    Ex1 = 550
    Ey1 = 330+levelY
    ESpeedx1 = 0
    Espeedy1 = 0
    EStartImage1  = 313
    EEndImage1    = 314
    EImageDelay1  =  3
    ENextImageDelay1 = EImageDelay
    EActualImage1 = 313
    EArmor1 = 50
    Epointvalue1 = 25000
    Edirectionx1 = Random(1)
    Edirectiony1 = Random(1)
    Eweapon1 = 205
    Eweaponstrength1 = 1
    Ebspeedx1 = -3
    Ebspeedy1 = 0
    Eattacktype1 = 2
    Emisc1 = 1
    Eflight1 = 1
    Edeaddelay = 5
    Gosub AddBoss
    For k = 0 To 120 Step 40
      Eshotchance1 = 0
      Ex1 = 400-k
      Ey1 = 335+levelY
      ESpeedx1 = 0
      Espeedy1 = 0
      EStartImage1  = 279
      EEndImage1    = 281
      EImageDelay1  =  3
      ENextImageDelay1 = EImageDelay
      EActualImage1 = 279
      EArmor1 = 15
      Epointvalue1 = 2502
      Edirectionx1 = 0
      Edirectiony1 = 0
      Eweapon1 = 205
      Eweaponstrength1 = 1
      Ebspeedx1 = -3
      Ebspeedy1 = 0
      Eattacktype1 = 2
      Emisc1 = 1
      Eflight1 = 1
      Edeaddelay = 5
      Gosub AddBoss
    Next 
 
  ElseIf lvl =8 And boss = 0
    backgroundmap = 2
    backgroundspeedx=-4
    backgroundspeedy=0
    levely = 0
    lvlsound = 30
    levelspeed = -3

    itemfrequency = 40 ; if random(itemfrequency) < 10
    lvldifficulty = 180
    howMany = 2
    
    EStartImage1  = 283
    EEndImage1    = 291
    EActualImage1 = 283
    Eattacktype1 = 0  
    Ebspeedx1 = -5
    Ebspeedy1 = 0     ; reqular
    EspeedX1 = 5
    EspeedY1 = 3
    Eweapon1 = 200
    Eshotchance1 = -1000
    EArmor1 = 1
    Epointvalue1 = 50
    Eweaponstrength1 = 1
    Eflight1 = 1
   
    enemyset = 1
    
    Emisc1 = 0

    EImageDelay  =  5  
    ENextImageDelay = EImageDelay
    Edeaddelay = 20
    
  ElseIf lvl =8 And boss = 1
    Gosub DeleteEnemies
    backgroundspeedx=-4
    backgroundspeedy=0
    levelspeed = 0
    itemfrequency = 0 
    
    Eshotchance1 = 10
    Ex1 = 255
    Ey1 = 270+levelY
    ESpeedx1 = 0
    Espeedy1 = 0
    EStartImage1  = 313
    EEndImage1    = 314
    EImageDelay1  =  3
    ENextImageDelay1 = EImageDelay
    EActualImage1 = 313
    EArmor1 = 15
    Epointvalue1 = 15000
    Edirectionx1 = Random(1)
    Edirectiony1 = Random(1)
    Eweapon1 = 205
    Eweaponstrength1 = 1
    Ebspeedx1 = -5
    Ebspeedy1 = -5
    Eattacktype1 = 2
    Emisc1 = 1
    Eflight1 = 1
    Edeaddelay = 5
    Gosub AddBoss
 
  Else
    Gosub saveHiScore 
    Gosub BeatGame
  EndIf 

  If boss = 0
    enemydelay = 100
    LevelImage = 500+lvl
    
    If IsSprite(#LevelImage)
      FreeSprite(#LevelImage)     
    EndIf 
    ;LoadSprite(#LevelImage,file$+"level\jpg\"+"level_"+Str(levelimage-500)+".jpg",#PB_Sprite_Memory )
    If lvl = 1 
      CatchSprite(#LevelImage, ?level1, #PB_Sprite_Memory) 
    ElseIf lvl = 2 
      CatchSprite(#LevelImage, ?level2, #PB_Sprite_Memory) 
    ElseIf lvl = 3 
      CatchSprite(#LevelImage, ?level3, #PB_Sprite_Memory) 
    ElseIf lvl = 4 
      CatchSprite(#LevelImage, ?level4, #PB_Sprite_Memory) 
    ElseIf lvl = 5 
      CatchSprite(#LevelImage, ?level5, #PB_Sprite_Memory) 
    ElseIf lvl = 6 
      CatchSprite(#LevelImage, ?level6, #PB_Sprite_Memory) 
    ElseIf lvl = 7
      CatchSprite(#LevelImage, ?level7, #PB_Sprite_Memory) 
    ElseIf lvl = 8
      CatchSprite(#LevelImage, ?level8, #PB_Sprite_Memory) 
    EndIf  
    
    levelheight = SpriteHeight(#LevelImage)
    levellength = SpriteWidth(#LevelImage)
    levelx = screenx
  Else
     enemydelay = 0
     levelx = - levellength + screenx
  EndIf 
  
    lvldifficulty = lvldifficulty / mode
    
   
    If playery > levelheight - playerheight
      playerY = levelHeight/2
    EndIf 
  
    lvlsound = 30 ; ******************************* remove later
 
    If playsound = 1
      PlaySound(lvlsound,1)
    EndIf 
      
      LoadSprite(#background,file$+"back_"+Str(backgroundmap)+".bmp",0)
      backgroundWidth = SpriteWidth(#background)
      backgroundHeight = SpriteHeight(#background)

EndIf 

do = 0
Return 


;**********************************************************
;
;- MusicFade Routine
;
;**********************************************************

MusicFade:
If playsound = 1
  If IsSound(lvlsound)
    StopSound(lvlsound)
  EndIf 
EndIf
Return 


;**********************************************************
;
;- Dead Routine
;
;**********************************************************

dead:
AddElement(explosion())
explosion()\x = playerX
explosion()\y = playerY
Dead = 1
DeadDelay = 100
lives-1
If lives < 0
  gameover = 1 
  Gosub MusicFade
  Gosub saveHiScore
EndIf 

shield = 1

If charge = 1
  StopSound(2)
EndIf

beam0 = 1  ; shouldn't need to do this...but i am
If special > 0
  special-1
  If special <0
    special = 0
  EndIf 
Else
  If beamselect = 0
    weaponselect-2
    If weaponselect < 10
      weaponselect = 10
    EndIf
    weaponstrength = (weaponselect-10)/2 + 1
    weaponspeed = (weaponselect-10)/3 + 16
  ElseIf beamselect = 1
    beamselect = 0
    beam1 = 0
  ElseIf beamselect = 2
    beamselect = 0 
    beam2 = 0
  ElseIf beamselect = 3
    beamselect = 0 
    beam3 = 0
  ElseIf beamselect = 4 
    beamselect = 0
    beam4 = 0
    charge = 0
  EndIf 
EndIf 
beam = beamselect
playerimage = shield
playerspeedX=3
playerspeedY=3
If lvl = 6 ; *** speed level :) dont dies!!!
;  levelx = 800
   playerSpeedX = 6
   playerSpeedY = 6
EndIf 
playery = 250 - PlayerWidth/2

  While SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx+PlayerWidth + 10,levely) Or SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx,levely-10) Or SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx,levely + playerHeight + 10)
    playery+playerheight
    If playery>500-playerHeight And (SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx+PlayerWidth + 10,levely) Or SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx,levely-10) Or SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx,levely + playerHeight + 10))
    playery=0
    While SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx+PlayerWidth + 10,levely) Or SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx,levely-10) Or SpritePixelCollision(playerimage,playerx,playery,#LevelImage,levelx,levely + playerHeight + 10)
      playery+playerHeight
    Wend
    EndIf 
  Wend

Goto main 


;**********************************************************
;
;- NewGame Routine
;
;**********************************************************

NewGame:

  effectvolume = 5
  For k= 1 To 5
    SoundVolume(k,effectvolume)
  Next 
  
  Backvolume = 100
  Backbalance = 0
  Gosub DeleteEnemies
  Gosub DeleteEnemyBullets
  Gosub DeleteItems
  Gosub DeleteBullets
  Gosub loadHiScore
  lives = 5
  score = 0
  If bonusLevel = 0
    lvl = 0
  Else 
    lvl = 8
  EndIf 
  lastLevel = 7
  lvlup = 1
  miss = 0
  hit = 0
  beam = 0 
  beamselect = 0
  beam0 = 1
  beam1 = 0
  beam2 = 0
  beam3 = 0
  beam4 = 0
  special = 0
  weaponselect=10
  weaponstrength = (weaponselect-10)/2 + 1
  weaponspeed = (weaponselect-10)/3 + 16
  weaponsound=0

  shield = 1  ; life
  PlayerImage = 1
  PlayerWidth  = SpriteWidth(PlayerImage)
  PlayerHeight = SpriteHeight(playerImage)
  PlayerX = 100 
  PlayerY = screenY/2 
  playerspeedX=3
  playerspeedY=3
  bulletspeedx=10 
  bulletspeedy=10
  paused = 0
  
  boss = 1
  enemykill = 0
  levelx = -5000; for purpose of gosub level, reset to lvllength
  levellength = 0
  deaddelay=75
Return  






;**********************************************************
;
;- Input Routines
;
;**********************************************************


WeaponCycle:
    If selectdelay <= 0

          If beamselect =0 
            If beam1=1
              beamselect = 1
            ElseIf beam2 = 1
              beamselect = 2
            ElseIf beam3 = 1
              beamselect = 3
            ElseIf beam4 = 1
              beamselect = 4
            Else 
              beamselect = 0           
            EndIf
          ElseIf beamselect =1 
            If beam2=1
              beamselect = 2
            ElseIf beam3 = 1
              beamselect = 3
            ElseIf beam4 = 1
              beamselect = 4
            Else 
            beamselect = 0
            EndIf
          ElseIf beamselect =2
            If beam3=1
              beamselect = 3
            ElseIf beam4 = 1
              beamselect = 4
            Else
              beamselect = 0
            EndIf
          ElseIf beamselect =3
            If beam4 = 1
              beamselect = 4
            Else
              beamselect = 0
            EndIf 
          ElseIf beamselect =4
              beamselect = 0
          EndIf 
                          
      beam = beamselect
      selectdelay = 15
      
    EndIf 
Return 





SpeedDown:

    If  selectdelay <= 0
      PlayerSpeedX-1
      PlayerSpeedY-1
      If playerSpeedX < 3 Or PlayerSpeedY < 3
        playerSpeedX = 3
        playerSpeedY = 3
      EndIf 
      selectdelay = 15
    EndIf 
Return 




Charging:

   If counter < 0
     If ElapsedMilliseconds() - chargetime < 1000
       DisplayTransparentSprite(chargeimage,playerX+8,playerY-5)
       chargeimage+1
       counter = 2
        If chargeimage>482
         chargeimage = 480
       EndIf 
                    
     Else 
     DisplayTransparentSprite(481,playerX+8,playerY-5)
     counter = 1 
     EndIf
   Else
     counter - 1
   EndIf 
Return 
      
      
      
ReleaseCharge:
   chargetime = ElapsedMilliseconds() - chargetime
   If chargetime > 1500
     chargetime = 1500
   EndIf
    damage = chargetime/500+1
    AddBullet(399+beam+chargetime/500, PlayerX+25 , playerY-chargetime/60, 18, 0, damage,100)     
    If special >=1
      AddBullet(399+beam+chargetime/500, PlayerX -30, playerY-chargetime/60, -18, 0, damage,100) 
    EndIf  
    If playsound = 1     
      StopSound(2)
    EndIf 
    charge = 0
    joystickreleased = 0
    
Return 




Shoot:

        If beamselect = 0   ;good ol' bullets
          BulletDelay = weaponspeed
          If weaponselect=10
            num=150
          Else 
            num=149
          EndIf 
          ; AddBullet() syntax: (#Sprite, x, y, SpeedX, SpeedY,life,type)
          AddBullet(weaponselect, PlayerX+50 , PlayerY-5,  bulletSpeedx, 0, weaponstrength,0) 
          If special>=1
            addbullet(weaponselect+num-10,playerX-20, playerY-5, -bulletSpeedx, 0, weaponstrength,0)
            If special>=2
              AddBullet(weaponselect+num, PlayerX , PlayerY-10, 0, -bulletSpeedy, weaponstrength,0)
              AddBullet(weaponselect+num+10, PlayerX , PlayerY+30, 0, bulletSpeedy, weaponstrength,0)
            EndIf 
          EndIf 
          If playsound = 1     
            PlaySound(1,0)
          EndIf 

        ElseIf beamselect = 1   ; homming beam
          BulletDelay = 25
        ;  If NextElement(enemy()) 
            k=0 
            ResetList(enemy())
            While NextElement(enemy())
              If enemy()\weaponstrength > 0
                If k <= special*2 +2
                y = (enemy()\y - playerY)/Sqr(Pow((enemy()\y - playerY),2) + Pow((enemy()\X - playerX),2))  ; :P never thought id use vectors..
                x = (enemy()\X - playerX)/Sqr(Pow((enemy()\y - playerY),2) + Pow((enemy()\X - playerX),2))  
                x+(enemy()\x - playerX)/(14-special)
                y+(enemy()\y - playerY)/(14-special)
                k+1 
                  AddBullet(399+beam, PlayerX+40 , playerY+5, x, y, 1,0)
                EndIf   
              EndIf
              If playsound = 1     
                PlaySound(1,0)
              EndIf 
            Wend    
          If k= 0
            AddBullet(399+beam, PlayerX+50 , playerY-5, 18, 0, 1,0)  
          EndIf 
        ElseIf beamselect = 2   ; plasma
            bulletdelay = 25
            If special <1
              AddBullet(399+beam, PlayerX+50 , playerY-5, 14, 0, 3,0)    
            ElseIf special >=  1
              AddBullet(399+beam, PlayerX+50 , playerY-8, 14, 0, 3,0) 
              AddBullet(399+beam, PlayerX+50 , playerY+20, 14, 0, 3,0)              
              If special >=2
                AddBullet(399+beam, PlayerX-80 , playerY-8, -14, 0, 3,0) 
                AddBullet(399+beam, PlayerX-80 , playerY+20, -14, 0, 3,0)  
              EndIf
            EndIf 
            If playsound = 1    
              PlaySound(special+1,0)
            EndIf  
        ElseIf beamselect = 3  ; the vulcan
          Bulletdelay = 30
          If special<2
            AddBullet(399+beam, PlayerX+50 , playerY-5, 11, -10, 1,0) 
            AddBullet(399+beam, PlayerX+50 , playerY-5, 13, -6, 1,0) 
            AddBullet(399+beam, PlayerX+50 , playerY-5, 15, -2, 1,0) 
            AddBullet(399+beam, PlayerX+50 , playerY-5, 15,  2, 1,0) 
            AddBullet(399+beam, PlayerX+50 , playerY-5, 13,  6, 1,0)  
            AddBullet(399+beam, PlayerX+50 , playerY-5, 11, 10, 1,0)
            If special >0  
              AddBullet(399+beam, PlayerX-5 , playerY-5, 12, -8, 1,0)  
              AddBullet(399+beam, PlayerX-5 , playerY-5, 14, -4, 1,0)
              AddBullet(399+beam, PlayerX-5 , playerY-5, 15,  0, 1,0) 
              AddBullet(399+beam, PlayerX-5 , playerY-5, 14,  4, 1,0)  
              AddBullet(399+beam, PlayerX-5 , playerY-5, 12,  8, 1,0) 
            EndIf            
          ElseIf special >= 2
            AddBullet(399+beam+5, PlayerX+50 , playerY-5, 11, -10, 1,0) 
            AddBullet(399+beam+5, PlayerX-5 , playerY-5, 12, -8, 1,0)  
            AddBullet(399+beam+5, PlayerX+50 , playerY-5, 13, -6, 1,0) 
            AddBullet(399+beam+5, PlayerX-5 , playerY-5, 14, -4, 1,0)
            AddBullet(399+beam+5, PlayerX+50 , playerY-5, 15, -2, 1,0) 
            AddBullet(399+beam+5, PlayerX-5 , playerY-5, 15,  0, 1,0)
            AddBullet(399+beam+5, PlayerX+50 , playerY-5, 15,  2, 1,0) 
            AddBullet(399+beam+5, PlayerX-5 , playerY-5, 14,  4, 1,0) 
            AddBullet(399+beam+5, PlayerX+50 , playerY-5, 13,  6, 1,0) 
            AddBullet(399+beam+5, PlayerX-5 , playerY-5, 12,  8, 1,0) 
            AddBullet(399+beam+5, PlayerX+50 , playerY-5, 11, 10, 1,0)       
               
          EndIf
            If playsound = 1     
              PlaySound(1,0)
            EndIf           
       ElseIf beamselect = 4  ; charge 
            If charge = 0
              bulletdelay = 18
              chargetime = ElapsedMilliseconds() 
              charge = 1
              chargeimage = 480
            EndIf
            If playsound = 1     
              PlaySound(2,1)
            EndIf              
       EndIf
       
Return 

;**********************************************************
;
;- DeleteElements
;
;**********************************************************
DeleteEnemies:
    ResetList(enemy())
    While NextElement(enemy())
      DeleteElement(enemy())
    Wend 
    DeleteElement(enemy())
Return 

DeleteEnemyBullets:
    ResetList(enemyBullet())
    While NextElement(enemyBullet())
      DeleteElement(enemyBullet())
    Wend 
    DeleteElement(enemyBullet())
Return 

DeleteBullets:
    ResetList(Bullet())
    While NextElement(Bullet())
      DeleteElement(Bullet())
    Wend 
    DeleteElement(Bullet())
Return 

DeleteItems:
    ResetList(item())
    While NextElement(item())
      DeleteElement(item())
    Wend 
    DeleteElement(item())
Return 

;**********************************************************
;
;- Explosion
;
;**********************************************************
Explosion:
  ResetList(Explosion())
  While NextElement(Explosion()) 

    DisplayTransparentSprite(Explosion()\explosion+16, Explosion()\x, Explosion()\y)

    If Explosion()\Delay = 0
      If Explosion()\explosion = 0 
        If playsound = 1     
          PlaySound(5,0)
        EndIf 
      EndIf
        If Explosion()\explosion < 7   ; one image at a time
          Explosion()\explosion+1
          Explosion()\Delay = 3
        Else
          DeleteElement(Explosion())
          bossexplosion = 0                ; used for after boss dies it wont go to the level routine until all the explosions are done
        EndIf
    Else
      Explosion()\Delay-1
    EndIf
  Wend
Return 

;**********************************************************
;
;- DrawMenu
;
;**********************************************************
DrawMenu:
      DisplaySprite(498,0,500)
      
      StartDrawing(ScreenOutput())
        DrawingMode(0)
        BackColor(0,0,0)
        FrontColor(255,255,255)
        Locate(10,505)
        DrawText("HI SCORE "+Str(hiscore))
        Locate(10,520)
        DrawText("SCORE "+Str(score))
        Locate(10,535)
        DrawText("LEVEL "+Str(lvl))
        Locate(90,565)
        If lives >= 0
          DrawText("x "+Str(lives))
        Else 
          DrawText("x 0")         ; dont want it to show -1
        EndIf 
        Locate(150,570)
        DrawText("POWER "+Str(weaponselect-10))
        Locate(320,570)
        DrawText("SPEED ")
        Locate(320,505)
        DrawText("MODE:")
        Locate(380,505)
        If mode = 1
          DrawText("Easy")
        ElseIf mode = 2
          DrawText("Normal")
        ElseIf mode = 3
          DrawText("Hard")
        Else 
          DrawText("Super Ultra Mega Hard")
        EndIf 
        
        Locate(320,520)
        DrawText("HIT%")
        If hit+miss = 0
          t.f = 0
        Else
          t.f = (hit/(hit+miss)*100)
        EndIf
        Locate(380,520) 
        DrawText(Str(Round(t,0)))
        
        If beam0=1
          Locate(250,510)
          DrawText("Phazor")
        EndIf
         
        If beam1=1
          Locate(250,525)
          DrawText("Homing")
        EndIf 
        If beam2=1
          Locate(250,540)
          DrawText("Plasma")
        EndIf 
        If beam4>=1
          Locate(250,570)
          DrawText("Charge")
        EndIf 
        If beam3>=1
          Locate(250,555)       ; beam 3 and 4 are out of order and ill consider fixing all the trash later
          DrawText("Vulcan")
        EndIf 
        Locate(240,510 + beamselect*15)
        DrawText("*")
      StopDrawing()
      
      k = playerSpeedX
      i = 0
      While k > 3
        i+17
        DisplaySprite(499,320+i,547)
        k-1
      Wend 

      DisplaySprite(494+shield,20,555)   ;  DisplaySprite(playerimage+494,20,555)

      DisplaySprite(weaponselect,150,510 )
      If gameover = 1
        BitmapText("GAME OVER",320,280)
      EndIf 
      
      If levelx < -levellength+1600 And levelx > -levellength+800
        BitmapText("BOSS INCOMING",320,240)
      EndIf 
        
Return 

;**********************************************************
;
;- DrawBackground
;
;**********************************************************
DrawBackground:
      
      x = -backgroundwidth                         
      y = -backgroundHeight  
      While x < screenX+backgroundwidth
        While y < screenY+backgroundheight
          DisplaySprite(background, x+ScrollX, y + ScrollY)
          y + backgroundHeight
        Wend 
        y = -backgroundHeight
        x + backgroundWidth
      Wend 
      
      ScrollY+backgroundspeedy            ; only support scrolling from right to left
      If Scrolly < -backgroundHeight      ; or ScrollY>backgroundHeight 
        ScrollY = 0
      EndIf
 
      ScrollX+backgroundspeedx
      If scrollX < -backgroundwidth       ; or ScrollX>backgroundWidth 
        ScrollX = 0
      EndIf
Return 

;**********************************************************
;
;- DrawTitleScreen
;
;**********************************************************
DrawTitleScreen:
  Gosub initJoystick
  exit = 0
  playerX = 390
  playerY = 290
  Gosub musicFade
  Gosub loadHiScore
  
 
  While exit = 0 
    
    If joystick = 1
      ExamineJoystick()
    EndIf
    ExamineKeyboard()
    If KeyboardPushed(#PB_Key_Escape)
      End 
    EndIf
    If KeyboardPushed(#PB_Key_Up) Or (joystick = 1 And JoystickAxisY() = -1)
      playerY-2
    EndIf 
    If KeyboardPushed(#PB_Key_Down) Or (joystick = 1 And JoystickAxisY() = 1)
      playerY+2
    EndIf 
    If KeyboardPushed(#PB_Key_Left) Or (joystick = 1 And JoystickAxisX() = -1)
      playerX-2
    EndIf 
    If KeyboardPushed(#PB_Key_Right) Or (joystick = 1 And JoystickAxisX() = 1)
      playerX+2
    EndIf 
    If playerX > screenX-SpriteWidth(510) 
      playerX = screenX-SpriteWidth(510) 
    EndIf 
    If playerX < 0
      playerX = 0
    EndIf
    If playerY < 0 
      playerY = 0
    EndIf     
    If playerY > screenY-SpriteHeight(510) 
        playerY = screenY-SpriteHeight(510) 
    EndIf
    
    If KeyboardPushed(#PB_Key_Return) Or KeyboardPushed(#PB_Key_Space) Or (joystick = 1 And JoystickButton(3))
      If playerX >=346 And playerX < = 430 And playerY > 245  And playerY < 275
        mode = 1
        If playsound = 1
          PlaySound(2,0)
        EndIf
        Break 
      ElseIf playerX >=320 And playerX < = 470 And playerY > 278  And playerY < 302
        mode = 2
        If playsound = 1
          PlaySound(2,0)
        EndIf
        Break
      EndIf 
      If unlock > 0 
        If playerX >=346 And playerX < = 435 And playerY >306  And playerY < 332
          mode = 3
          If playsound = 1
            PlaySound(2,0)
          EndIf
          Break 
        EndIf 
      EndIf 
      If unlock > 1
        If playerX >=170 And playerX < = 645 And playerY > 336  And playerY < 360
          mode = 4
          If playsound = 1
            PlaySound(2,0)
          EndIf
          Break 
        EndIf 
      EndIf 
      If unlock > 2
        If playerX >=280 And playerX < = 535 And playerY > 368  And playerY < 397
          mode = 4
          bonusLevel = 1
          If playsound = 1
            PlaySound(2,0)
          EndIf
          Break 
        EndIf 
      EndIf 
    EndIf
    k = 501
    If beatGame = 1
      k = 502
    EndIf 
    DisplaySprite(k,0,0)
    bitmapText("EASY",360,260)
    bitmapText("NORMAL",330,290)
    If unlock > 0
      bitmapText("HARD",360,320)
    EndIf 
    If unlock > 1
      bitmapText("SUPER ULTRA MEGA HARD",180,350)
    EndIf 
    If unlock > 2
      bitmapText("SECRET MODE",290,380)
    EndIf 
    bitmapText("HI SCORE",330,410)
    bitmapText(Str(hiscore),350,440)
    bitmapText(hiPlayer$,350,470)
    bitmapText("MAX KILLS",310,500)
    bitmapText(Str(maxEnemKilled),350,530)
    k = 510
    If beatGame = 1
      k = 511
    EndIf 
      DisplayTransparentSprite(k, playerX, playerY)
    
    FlipBuffers()
  Wend 
  Gosub musicFade
Return 


;**********************************************************
;
;- BetweenLevels
;
;**********************************************************
BetweenLevels:
  ClearScreen(0,0,0)
  If bonusLevel = 1
    BitmapText("UNKNOWN LANDS", 265, 275)
  ElseIf lvl = 1
    BitmapText("METROPOLA", 300, 275)
  ElseIf lvl = 2
      BitmapText("THE OASIS", 300, 275)
  ElseIf lvl = 3
      BitmapText("METEORA", 300, 275)
  ElseIf lvl = 4
      BitmapText("RED BARON", 300, 275)
  ElseIf lvl = 5
      BitmapText("THE CAVES", 300, 275)
  ElseIf lvl = 6
      BitmapText("THE CELERON", 300, 275)
  ElseIf lvl = 7
      BitmapText("ASSEMBLER", 300, 275)
  EndIf 
  FlipBuffers()

Return 


;**********************************************************
;
;- BeatGame
;
;**********************************************************
BeatGame:
For y = 900 To -1550 Step -1
  ClearScreen(0,0,0)
  BitmapText("CONGRATULATIONS", 200, y)
  BitmapText("PEACE HAS BEEN RESTORED", 200, y+50)
  BitmapText("TO THE UNIVERSE", 200, y+100)
  
  BitmapText("CREDITS", 280, y+300)
  BitmapText("PROGRAMMER  ", 200, y+350)
  BitmapText("KENNY CASON", 280, y+400)
  BitmapText("CUSTOM GRAPHICS ", 200, y+450)
  BitmapText("KENNY CASON", 280, y+500)
  BitmapText("DAVID JOHNSON", 280, y+550)
  BitmapText("JOSH DAUGHERTY", 280, y+600)
  
  BitmapText("MUSIC", 200, y+650)
  BitmapText("TONY LOFTON", 280, y+700)
  
  BitmapText("OTHER THANKS", 200, y+750)
  BitmapText("UAGDC", 280, y+800)
  BitmapText("PUREBASIC", 280, y+850)
  BitmapText("NINTENDO", 280, y+900)
  BitmapText("MICHAEL BIEBESHEIMER", 280, y+950) 
  BitmapText("BETA TESTERS", 200, y+1000)
  BitmapText("DAVID JOHNSON", 280, y+1050)
  BitmapText("JOHN DEFOREST", 280, y+1100)
  BitmapText("CONNIE JIANG", 280, y+1150)
  BitmapText("GLADSON RIPLEY", 280, y+1200)
  
  BitmapText("THE END", 280, y+1700)
  BitmapText("ENEMIES KILLED", 280, y+1750)
  BitmapText(Str(enemyKill), 280, y+1800)
  BitmapText("SCORE", 280, y+1850)
  BitmapText(Str(score), 280, y+1900)
  BitmapText("HIT PERCENTAGE", 280, y+1950)
  If miss + hit = 0
    t.f = 0
  Else
    t.f = (hit/(hit+miss)*100)
  EndIf 
  BitmapText(Str(Round(t,0)), 280, y+2000)
  If miss + hit > 0
    t.f = (hit/(hit+miss)*100)
    If t >= 100
      BitmapText("PERFECT SHOOTING", 280, y+2050)
    ElseIf  t > 90
      BitmapText("SUPERB SHOOTING", 280, y+2050)
    ElseIf  t > 75
      BitmapText("NICE SHOOTING", 280, y+2050)  
    ElseIf  t > 65
      BitmapText("GOOD SHOOTING", 280, y+2050)  
    ElseIf  t > 50
      BitmapText("AVERAGE SHOOTING", 280, y+2050) 
    ElseIf  t > 30
      BitmapText("BAD SHOOTING", 280, y+2050)   
    ElseIf  t > 10
      BitmapText("TERRIBLE SHOOTING", 280, y+2050) 
    Else 
      BitmapText("HORRIFIC SHOOTING", 280, y+2050)          
    EndIf 
  Else  
    BitmapText("WORST SHOOTER ALIVE", 280, y+2050) 
  EndIf 
  FlipBuffers()
Next 
  Delay(3000)
  If mode = 2 And unlock < 1
    unlock = 1
  ElseIf  mode = 3 And unlock < 2
    unlock = 2
  ElseIf  mode = 4 And unlock < 3
    unlock = 3
  EndIf 
  If mode > 2
    beatGame = 1
  EndIf 
  If (hit+miss) > 0
    score + (hit/(hit+miss)*100)*250
  EndIf 
  
Gosub saveHiScore
Gosub DrawTitleScreen
Gosub newgame 
FakeReturn 
Goto level:
Return 


;**********************************************************
;
;- loadHiScore
;
;**********************************************************
loadHiScore:
  If ReadFile(0, "vulcan.vc")
    hiscore = (ReadLong()+1234567890)
    unlock = (ReadLong()+1234567890)
    gameBeat = (ReadLong()+1234567890)
    maxEnemKilled = (ReadLong()+1234567890)
    hiPlayer$ = ReadString()
    If unlock < 0 Or unlock > 3
      unlock = 0
    EndIf 
    CloseFile(0)
  EndIf 
Return 

;**********************************************************
;
;- saveHiScore
;
;**********************************************************
saveHiScore:
If score > hiscore
  hiscore = score
  Gosub inputName
EndIf 
If enemyKill > maxEnemKilled
  maxEnemKilled = enemyKill
EndIf 
If OpenFile(0, "vulcan.vc")
  WriteLong((hiscore-1234567890))
  WriteLong((unlock-1234567890))
  WriteLong((gameBeat-1234567890))
  WriteLong((maxEnemKilled-1234567890))
  WriteString(hiPlayer$)
  CloseFile(0)
EndIf 

Return 


;**********************************************************
;
;- inputName
;
;**********************************************************
inputName:
  exit = 0
  hiPlayer$ = ""
  string$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
  While exit = 0
    ClearScreen(0,0,0)
    bitmapText("YOU HAVE A HISCORE", 250, 250)
    bitmapText("ENTER YOUR NAME", 250, 280)
    bitmapText(hiPlayer$, 250, 340)
    If k > Len(string$) 
      k = Len(string$)
    ElseIf k < 1
      k = 1
    EndIf 
    bitmapText(Mid(string$,k,1), 300, 310)
    FlipBuffers()

    ExamineKeyboard()
    If joystick = 1
      ExamineJoystick()
    EndIf
    If KeyboardPushed(#PB_Key_Return) Or (joystick = 1 And JoystickButton(2) )
      exit = 1
    EndIf 
    If KeyboardPushed(#PB_Key_Back) Or (joystick = 1 And JoystickButton(1) )
      hiPlayer$ = Mid(hiPlayer$,1,Len(hiPlayer$)-1)
      Delay(200)
    EndIf 
    If KeyboardPushed(#PB_Key_Space) Or (joystick = 1 And JoystickButton(3) )
      If Len(hiPlayer$) < 6
        hiPlayer$+Mid(string$,k,1)
        Delay(200)
      EndIf
    EndIf 
    If KeyboardPushed(#PB_Key_Left) Or (joystick = 1 And JoystickAxisX() = -1 ) Or (joystick = 1 And JoystickButton(7) )
      k-1 
      Delay(100)
    EndIf 
    If KeyboardPushed(#PB_Key_Right) Or (joystick = 1 And JoystickAxisX() = 1 ) Or (joystick = 1 And JoystickButton(8) )
      k+1
      Delay(100)
    EndIf 
  Wend 
  For k = Len(hiPlayer$) To 5
    hiPlayer$+ " "
  Next
  ClearScreen(0,0,0)
Return 


;**********************************************************
;
;- initJoystick
;
;**********************************************************
initJoystick:
  If joystick = 0 And initedJoystick = 0
    If InitJoystick()
      joystick = 1
      initedJoystick = 1
    Else
      joystick = 0
      initedJoystick = 1
    EndIf 
  EndIf 
Return 
; IDE Options = PureBasic 5.50 (MacOS X - x64)
; CursorPosition = 789
; FirstLine = 784
; Folding = -
; EnableXP
; UseIcon = D:\purebasic\Projects\Vulcan I programming\vulcan I.ico
; Executable = ../../Vulcan I programming/vulcan I.exe
; DisableDebugger