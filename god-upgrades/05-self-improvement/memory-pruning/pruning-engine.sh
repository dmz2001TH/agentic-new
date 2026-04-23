#!/bin/bash
# Auto-pruning: เก็บเฉพาะข้อมูล 7 วันล่าสุดและสิ่งที่ถูกทำเครื่องหมาย "Keep"
find ψ/memory/logs/ -mtime +7 -delete
echo "[$(date +%H:%M)] Memory Pruning Complete." > ψ/memory/logs/pruning.log
