#pragma once

struct OSDevice {
    void (*readBinaryFile)(const char* fileName, u8** fileData, u64* fileLength);
    void (*readTextFile)(const char* fileName, s8** fileData, u64* fileLength);
};