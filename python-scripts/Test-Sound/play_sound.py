#!/usr/bin/python
# -*- coding: UTF-8 -*-
"""Pequeño Script para la demostración de reproducción de sonido con Python

Para poder utilizar este pequeño script es necesario tener instalado varias librerias entre ellas

    - pydub
    - pyaudio

Y tambien es necesario tener instalado en el sistema las librerias ffmpeg tanto si lo usamos en windows como en linux
estás librerias son de libre distribución y tienen soporte multi-os.

Las demas librerias del script son para poder mostrar el spectograma del audio.
"""

from pydub import AudioSegment as mix
from pydub.playback import play
import matplotlib.pyplot as plt
import numpy as np
import wave
import sys

def leer_wave(filename):
    spf = wave.open(filename, 'r')
    params = spf.getparams()
    framerate= params[2]
    x = spf.readframes(-1)
    x = np.fromstring(x, 'Int16')
    plt.title(filename)
    plt.plot(x)
    plt.show()
    return x, framerate

def representa_espectrograma(x, NFFT, Fs, noverlap):
    Pxx, freqs, bins, im= plt.specgram(x, NFFT=NFFT, Fs=Fs, cmap='jet', noverlap=noverlap)
    plt.ylabel('Frequencia [Hz]')
    plt.xlabel('Tiempo [seg]')
    return Pxx, freqs

def reproducir(filename):
    play(mix.from_wav(filename))

if __name__ == '__main__':
    filename = sys.argv[1]
    reproducir(filename)
    x, framerate = leer_wave(filename)
    representa_espectrograma(x, 256, framerate, 128)
