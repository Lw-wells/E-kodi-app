#E-KODI - Smart Rent & Utility Management System


📋 #Table of Contents
Project Overview

Features

Technology Stack

Prerequisites

Installation Guide

Firebase Setup

Environment Configuration

Project Structure

Running the Application

Authentication Flow

Database Structure

API Integration

Testing

Building for Production

Troubleshooting

Contributing

License


🏠 #Project Overview
E-Kodi is a comprehensive property management solution designed specifically for the Kenyan rental market. It bridges the gap between landlords and tenants by automating rent collection, utility bill management, and communication through a modern digital platform.

Problem Statement
Landlords struggle with manual record-keeping using notebooks or Excel

Revenue leakage from uncollected utility bills

Tenants lack transparency in billing

No efficient communication channel between landlords and tenants

Difficulty tracking payments across multiple properties

#Our Solution
E-Kodi provides:

For Landlords: Web dashboard and Flutter mobile app for property management

For Tenants: Simple WhatsApp bot for payments and inquiries

Automated: M-Pesa integration for seamless rent collection

Real-time: Instant payment confirmation and receipt generation

Analytics: Financial reports and property performance metrics

✨ #Features
Landlord Features
✅ Property Management: Add, edit, and manage multiple properties

✅ Tenant Management: Track tenants, lease agreements, and contact details

✅ Payment Processing: Initiate M-Pesa STK Push payments

✅ Utility Billing: Manage water, electricity, and other bills

✅ Financial Reports: Generate revenue reports, tax summaries

✅ Real-time Dashboard: View occupancy rates, payment trends

✅ Communication: Send announcements via WhatsApp/SMS

✅ Document Storage: Store receipts, lease agreements, tenant IDs

#Tenant Features
✅ WhatsApp Bot: Pay rent via simple text commands

✅ Balance Inquiry: Check outstanding balance anytime

✅ Payment History: View past payment records

✅ Receipt Retrieval: Download payment receipts (PDF)

✅ Maintenance Requests: Report issues via WhatsApp

✅ Announcements: Receive important updates from landlord

#Technical Features
✅ Cross-platform (Android, iOS, Web)

✅ Offline capability for mobile app

✅ Real-time data synchronization

✅ Secure authentication with Firebase

✅ M-Pesa integration (Daraja API)

✅ PDF receipt generation

✅ Push notifications

🛠 #Technology Stack
Layer	Technology	Version
Frontend (Mobile)	Flutter	3.x
Frontend (Web)	React + Material-UI	18.x
Backend	Node.js + Express	20.x
Payment Service	Python + Flask	3.10
Database	PostgreSQL	14+
Cache	Redis	7.x
Real-time	Firebase Firestore	Latest
Authentication	Firebase Auth	Latest
File Storage	Firebase Storage / MinIO	Latest
Queue System	RabbitMQ / PGQ	3.x
WhatsApp	Twilio API / Evolution API	Latest
M-Pesa	Safaricom Daraja API	v1


📋 #Prerequisites
Before you begin, ensure you have the following installed:
