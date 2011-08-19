#!/usr/bin/env python

import sys, pygame
import pygame.draw
from random import randint, sample
pygame.init()

objects = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
backgrounds = int(sys.argv[2]) if len(sys.argv) > 2 else 5

black = 0, 0, 0
ssize = swidth, sheight = 800, 600

screen = pygame.display.set_mode(ssize, pygame.DOUBLEBUF)
backimg = pygame.image.load("dragon.jpg")
backimg = backimg.convert(screen)
back_rect = backimg.get_rect()
size = width, height = back_rect.width, back_rect.height
clock = pygame.time.Clock()
colors = [pygame.Color("red"),
       pygame.Color("blue"),
       pygame.Color("green"),
       pygame.Color("yellow"),
       pygame.Color(0, 255, 255),
       pygame.Color("grey"),
] 

balls = []
for i in xrange(1, objects):
    bspeed = 150.
    balls.append({"color": sample(colors, 1)[0], "size": randint(4, 16) * 2, "speed": (150. * sample([-1, 1], 1)[0], 150. * sample([-1, 1], 1)[0]), "coord": (randint(0, width) * 1., randint(0, height) * 1.)})

for ball in balls:
    ball["surface"] = pygame.Surface((ball["size"], ball["size"]), 0, screen)
    ball["surface"].fill(pygame.Color("magenta"))
    pygame.draw.circle(ball["surface"], ball["color"], (ball["size"] / 2, ball["size"] / 2), ball["size"] / 2)
    ball["surface"].set_colorkey(pygame.Color("magenta"))

camerapos = (320., 240.)

keys = {122: (0, -1), 100: (1, 0), 115: (0, 1), 113: (-1, 0)}
scroll_speed = 500.
scrolling = (0, 0)

font = pygame.font.Font(pygame.font.get_default_font(), 16)
fps_update_rate = 1.
fps_counter = fps_update_rate
fps = None
font_rect = None
fps_number = 0

while 1:
    deltat = clock.tick() / 1000.
    for event in pygame.event.get():
        if event.type == pygame.QUIT: sys.exit()
        elif event.type == pygame.KEYDOWN or event.type == pygame.KEYUP:
            if not event.key in keys:
                continue
            mult = 1 if event.type == pygame.KEYDOWN else -1
            scrolling = [x + (y * mult) for x, y in zip(scrolling, keys[event.key])]

    camerapos = [min(max(x + (y * scroll_speed * deltat), 0), z - a) for x, y, z, a in zip(camerapos, scrolling, size, ssize)]

    for ball in balls:
        ball["coord"] = [((x + (y * deltat) + ball["size"]) % (z + ball["size"] * 2)) - ball["size"] for x, y, z in zip(ball["coord"], ball["speed"], size)]
        ballrect = ball["surface"].get_rect()
        ballrect.center = ball["coord"]
        ballrect.center = [x - y for x, y in zip(ballrect.center, camerapos)]
        ball["rect"] = ballrect

    for i in xrange(0, backgrounds):
        screen.blit(backimg, pygame.Rect((0, 0), ssize), pygame.Rect(camerapos, ssize))

    for ball in balls:
        screen.blit(ball["surface"], ball["rect"])

    if fps_counter >= fps_update_rate:
        fps = font.render(str(fps_number), True, pygame.Color("white"))
        font_rect = fps.get_rect()
        font_rect.topright = (swidth, 0)
        fps_counter = fps_counter - fps_update_rate
        fps_number = 0
    screen.blit(fps, font_rect)
    pygame.display.flip()
    fps_number += 1
    fps_counter += deltat

