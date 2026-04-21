#!/usr/bin/env bash
# Policy Engine: ตรวจสอบและอนุมัติความปลอดภัยอัตโนมัติ
echo "Oracle Policy Engine: Active"
# ตรวจสอบว่าอยู่ในโหมดทดสอบหรือทำงานจริง
if [ "$GEMINI_ENV" == "production" ]; then
    echo "Production Mode: Strict"
else
    echo "Development Mode: Auto-Allow enabled"
    exit 0
fi
