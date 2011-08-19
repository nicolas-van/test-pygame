#!/usr/bin/env python

import sys, pygame
import pygame.draw
from random import randint, sample
import operator as op
import collections
#from numpy import array
import numpy
import UserList
#from statlib.matfunc import Table as array
import numbers

class UserTuple:
    def __init__(self, inittuple=None):
        self.data = ()
        if inittuple is not None:
            # XXX should this accept an arbitrary sequence?
            if type(inittuple) == type(self.data):
                self.data = inittuple
            elif isinstance(inittuple, UserTuple):
                # this results in
                #   self.data is inittuple.data
                # but that's ok for tuples because they are
                # immutable. (Builtin tuples behave the same.)
                self.data = inittuple.data
            else:
                # the same applies here; (t is tuple(t)) == 1
                self.data = tuple(inittuple)
    def __repr__(self): return repr(self.data)
    def __lt__(self, other): return self.data <  self.__cast(other)
    def __le__(self, other): return self.data <= self.__cast(other)
    def __eq__(self, other): return self.data == self.__cast(other)
    def __ne__(self, other): return self.data != self.__cast(other)
    def __gt__(self, other): return self.data >  self.__cast(other)
    def __ge__(self, other): return self.data >= self.__cast(other)
    def __cast(self, other):
        if isinstance(other, UserTuple): return other.data
        else: return other
    def __cmp__(self, other):
        return cmp(self.data, self.__cast(other))
    def __contains__(self, item): return item in self.data
    def __len__(self): return len(self.data)
    def __getitem__(self, i): return self.data[i]
    def __getslice__(self, i, j):
        return self.__class__(self.data[i:j])
    def __add__(self, other):
        if isinstance(other, UserTuple):
            return self.__class__(self.data + other.data)
        elif isinstance(other, type(self.data)):
            return self.__class__(self.data + other)
        else:
            return self.__class__(self.data + tuple(other))
    # dir( () ) contains no __radd__ (at least in Python 2.2)
    def __mul__(self, n):
        return self.__class__(self.data*n)
    __rmul__ = __mul__

class my_array(UserTuple):
    def _app(self, other, o):
        if isinstance(other, numbers.Number):
            return my_array((o(self[0], other), o(self[1], other)))
        else:
            return my_array((o(self[0], other[0]), o(self[1], other[1])))
    def __add__(self, other):
        return self._app(other, op.add)
    def __sub__(self, other):
        return self._app(other, op.sub)
    def __mul__(self, other):
        return self._app(other, op.mul)
    def __floordiv__(self, other):
        return self._app(other, op.floordiv)
    def __mod__(self, other):
        return self._app(other, op.mod)
    def __pow__(self, other, useseless=None):
        return self._app(other, op.pow)
    def __lshift__(self, other):
        return self._app(other, op.lshift)
    def __rshift__(self, other):
        return self._app(other, op.rshift)
    def __and__(self, other):
        return self._app(other, op.and_)
    def __xor__(self, other):
        return self._app(other, op.xor)
    def __or__(self, other):
        return self._app(other, op.or_)
    def __div__(self, other):
        return self._app(other, op.div)
    def __truediv__(self, other):
        return self._app(other, op.truediv)

array = my_array

pygame.init()

objects = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
backgrounds = int(sys.argv[2]) if len(sys.argv) > 2 else 5

black = 0, 0, 0
ssize = swidth, sheight = 800, 600
ssize = array(ssize)

screen = pygame.display.set_mode(ssize, pygame.DOUBLEBUF)
backimg = pygame.image.load("dragon.jpg")
backimg = backimg.convert(screen)
back_rect = backimg.get_rect()
size = width, height = back_rect.width, back_rect.height
size = array(size)
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
    balls.append({"color": sample(colors, 1)[0], "size": randint(4, 16) * 2, "speed": array([150. * sample([-1, 1], 1)[0] for x in range(2)]), "coord": array([randint(0, x) * 1. for x in size])})

for ball in balls:
    ball["surface"] = pygame.Surface((ball["size"], ball["size"]), 0, screen)
    ball["surface"].fill(pygame.Color("magenta"))
    pygame.draw.circle(ball["surface"], ball["color"], (ball["size"] / 2,) * 2, ball["size"] / 2)
    ball["surface"].set_colorkey(pygame.Color("magenta"))

camerapos = array((320., 240.))

keys = {122: (0, -1), 100: (1, 0), 115: (0, 1), 113: (-1, 0)}
keys = dict([(x, array(y)) for x, y in keys.items()])
scroll_speed = 500.
scrolling = array((0, 0))

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
            scrolling = scrolling + (keys[event.key] * mult)

    camerapos = [min(max(x + (y * scroll_speed * deltat), 0), z - a) for x, y, z, a in zip(camerapos, scrolling, size, ssize)]

    #camerapos = numpy.minimum(numpy.maximum(camerapos + (scrolling * scroll_speed * deltat), 0), size - ssize)

    for ball in balls:
        ball["coord"] = (ball["coord"] + ball["speed"] * deltat + ball["size"])  % (size + ball["size"] * 2) - ball["size"]
        #ball["coord"] = array([x % y for x, y in zip(ball["coord"] + ball["speed"] * deltat + ball["size"], size + ball["size"] * 2)]) - ball["size"]
        #ball["coord"] = [((x + (y * deltat) + ball["size"]) % (z + ball["size"] * 2)) - ball["size"] for x, y, z in zip(ball["coord"], ball["speed"], size)]
        ballrect = ball["surface"].get_rect()
        ballrect.center = array(ball["coord"]) - camerapos
        #ballrect.center = [x - y for x, y in zip(ball["coord"], camerapos)]
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

