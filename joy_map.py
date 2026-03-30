#!/usr/bin/env python3
"""
Joystick mapping helper.
Run this, then press each button/direction on your controller.
It will print the exact event type, button index, hat value, or axis value.
Press Escape or close the window to quit.
"""
import pygame

pygame.init()
screen = pygame.display.set_mode((480, 320))
pygame.display.set_caption("Joystick Mapper - press buttons/dpad")

pygame.joystick.init()
if pygame.joystick.get_count() == 0:
    print("No joystick detected! Make sure your controller is connected.")
    pygame.quit()
    exit(1)

joy = pygame.joystick.Joystick(0)
joy.init()
print(f"Controller: {joy.get_name()}")
print(f"  Buttons : {joy.get_numbuttons()}")
print(f"  Hats    : {joy.get_numhats()}")
print(f"  Axes    : {joy.get_numaxes()}")
print()
print("Press buttons/dpad/sticks now. Escape or close window to quit.")
print("-" * 50)

PROMPTS = [
    "Press D-pad UP",
    "Press D-pad DOWN",
    "Press D-pad LEFT",
    "Press D-pad RIGHT",
    "Press A (right cluster, bottom)",
    "Press B (right cluster, right)",
    "Press X (right cluster, top)",
    "Press Y (right cluster, left)",
    "Press START / Plus",
    "Press SELECT / Minus",
    "Press L shoulder",
    "Press R shoulder",
]
step = 0
print(f"\n>>> {PROMPTS[step]}")

font = pygame.font.SysFont(None, 28)
log = []

running = True
while running:
    screen.fill((20, 20, 40))

    # Current prompt
    if step < len(PROMPTS):
        txt = font.render(f">>> {PROMPTS[step]}", True, (255, 220, 80))
        screen.blit(txt, (20, 20))

    # Last 8 log lines
    for i, line in enumerate(log[-8:]):
        s = font.render(line, True, (180, 255, 180))
        screen.blit(s, (20, 60 + i * 28))

    pygame.display.flip()

    for ev in pygame.event.get():
        if ev.type == pygame.QUIT:
            running = False

        elif ev.type == pygame.KEYDOWN and ev.key == pygame.K_ESCAPE:
            running = False

        elif ev.type == pygame.JOYBUTTONDOWN:
            msg = f"BUTTON DOWN  index={ev.button}"
            print(msg)
            log.append(msg)
            step = min(step + 1, len(PROMPTS) - 1)
            if step < len(PROMPTS):
                print(f"\n>>> {PROMPTS[step]}")

        elif ev.type == pygame.JOYHATMOTION:
            msg = f"HAT MOTION   hat={ev.hat}  value={ev.value}"
            print(msg)
            log.append(msg)
            if ev.value != (0, 0):  # only advance on actual direction press
                step = min(step + 1, len(PROMPTS) - 1)
                if step < len(PROMPTS):
                    print(f"\n>>> {PROMPTS[step]}")

        elif ev.type == pygame.JOYAXISMOTION:
            if abs(ev.value) > 0.5:
                msg = f"AXIS MOTION  axis={ev.axis}  value={ev.value:.2f}"
                print(msg)
                log.append(msg)

pygame.quit()
print("\nDone. Use the output above to update JOY_* constants in vulcan.py.")
