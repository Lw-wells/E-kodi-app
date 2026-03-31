import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

const db = admin.firestore();

// ── Daraja sandbox credentials ─────────────────────────────────────────────
const CONSUMER_KEY = process.env.DARAJA_CONSUMER_KEY ?? "";
const CONSUMER_SECRET = process.env.DARAJA_CONSUMER_SECRET ?? "";
const PASSKEY = process.env.DARAJA_PASSKEY ?? "";
const SHORTCODE = process.env.DARAJA_SHORTCODE ?? "174379";
const DARAJA_BASE_URL = process.env.DARAJA_BASE_URL ?? "https://sandbox.safaricom.co.ke";
// ── Helper: get OAuth token 
//────────────────────────────────────────────────
async function getDarajaToken(): Promise<string> {
    const credentials = Buffer.from(
        `${CONSUMER_KEY}:${CONSUMER_SECRET}`
    ).toString("base64");

    const response = await axios.get(
        `${DARAJA_BASE_URL}/oauth/v1/generate?grant_type=client_credentials`,
        {
            headers: {
                "Authorization": `Basic ${credentials}`,
            },
        }
    );
    return response.data.access_token;
}
// async function getDarajaToken(): Promise<string> {
//     const credentials = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString("base64");
//     const response = await axios.get(
//         `${DARAJA_BASE_URL}/oauth/v1/generate?grant_type=client_credentials`,
//         { headers: { Authorization: `Basic ${credentials}` } }
//     );
//     return response.data.access_token;
// }

// ── Helper: timestamp format ───────────────────────────────────────────────
function getTimestamp(): string {
    const now = new Date();
    return [
        now.getFullYear(),
        String(now.getMonth() + 1).padStart(2, "0"),
        String(now.getDate()).padStart(2, "0"),
        String(now.getHours()).padStart(2, "0"),
        String(now.getMinutes()).padStart(2, "0"),
        String(now.getSeconds()).padStart(2, "0"),
    ].join("");
}

// ── 1. STK Push — triggered from Flutter ──────────────────────────────────
// Flutter calls this with: { phone, amount, tenantId, tenantName, unitName }
export const stkPush = functions.https.onCall(async (request) => {
    const { phone, amount, tenantId, tenantName, unitName } = request.data;

    if (!phone || !amount) {
        throw new functions.https.HttpsError("invalid-argument", "phone and amount are required");
    }

    try {
        const token = await getDarajaToken();
        const timestamp = getTimestamp();
        const password = Buffer.from(`${SHORTCODE}${PASSKEY}${timestamp}`).toString("base64");

        // Format phone: strip leading 0, add 254
        const formattedPhone = phone.startsWith("0")
            ? `254${phone.substring(1)}`
            : phone;

        const response = await axios.post(
            `${DARAJA_BASE_URL}/mpesa/stkpush/v1/processrequest`,
            {
                BusinessShortCode: SHORTCODE,
                Password: password,
                Timestamp: timestamp,
                TransactionType: "CustomerPayBillOnline",
                Amount: Math.round(amount),
                PartyA: formattedPhone,
                PartyB: SHORTCODE,
                PhoneNumber: formattedPhone,
                CallBackURL: "https://stkcallback-5c3kidf73q-uc.a.run.app",
                AccountReference: unitName ?? "Rent",
                TransactionDesc: `Rent payment for ${unitName}`,
            },
            { headers: { Authorization: `Bearer ${token}` } }
        );

        // Log pending transaction in Firestore
        await db.collection("mpesa_transactions").add({
            checkoutRequestId: response.data.CheckoutRequestID,
            tenantId,
            tenantName,
            unitName,
            amount,
            phone: formattedPhone,
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true, checkoutRequestId: response.data.CheckoutRequestID };

    } catch (error: any) {
        console.error("STK Push error:", error.response?.data ?? error.message);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

// ── 2. STK Callback — Safaricom calls this after payment ──────────────────
export const stkCallback = functions.https.onRequest(async (req, res) => {
    const body = req.body;
    const callback = body?.Body?.stkCallback;

    if (!callback) {
        res.status(400).send("Invalid callback");
        return;
    }

    const checkoutRequestId = callback.CheckoutRequestID;
    const resultCode = callback.ResultCode;   // 0 = success
    const resultDesc = callback.ResultDesc;

    try {
        // Find the pending transaction
        const snap = await db
            .collection("mpesa_transactions")
            .where("checkoutRequestId", "==", checkoutRequestId)
            .limit(1)
            .get();

        if (snap.empty) {
            res.status(200).send("OK");
            return;
        }

        const docRef = snap.docs[0].ref;
        const txData = snap.docs[0].data();

        if (resultCode === 0) {
            // Payment successful — extract M-Pesa details
            const items = callback.CallbackMetadata?.Item ?? [];
            const getValue = (name: string) =>
                items.find((i: any) => i.Name === name)?.Value ?? null;

            const mpesaCode = getValue("MpesaReceiptNumber");
            const amount = getValue("Amount");
            const phone = getValue("PhoneNumber");
            const paidAt = getValue("TransactionDate");

            // Update transaction to success
            await docRef.update({
                status: "success",
                mpesaCode,
                amount,
                phone,
                paidAt,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Write to finances collection for the ledger
            await db.collection("finances").add({
                type: "payment",
                amount,
                mpesaCode,
                phone,
                tenantId: txData.tenantId,
                tenantName: txData.tenantName,
                unitName: txData.unitName,
                description: `Rent payment — ${txData.unitName}`,
                status: "matched",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

        } else {
            // Payment failed or cancelled
            await docRef.update({
                status: "failed",
                resultDesc,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        res.status(200).send("OK");

    } catch (error) {
        console.error("STK callback error:", error);
        res.status(500).send("Error");
    }
});

export const registerC2BUrls = functions.https.onRequest(async (req, res) => {
    try {
        const token = await getDarajaToken();

        const response = await axios.post(
            `${DARAJA_BASE_URL}/mpesa/c2b/v1/registerurl`,
            {
                ShortCode: SHORTCODE,
                ResponseType: "Completed",
                ConfirmationURL: "https://c2bconfirmation-5c3kidf73q-uc.a.run.app",
                ValidationURL: "https://c2bvalidation-5c3kidf73q-uc.a.run.app",
            },
            { headers: { Authorization: `Bearer ${token}` } }
        );

        res.status(200).json(response.data);
    } catch (error: any) {
        res.status(500).json(error.response?.data ?? error.message);
    }
});

// ── 3. C2B Register URLs — run once to register your callback URLs ─────────
// export const registerC2BUrls = functions.https.onRequest(async (req, res) => {
//     try {
//         const token = await getDarajaToken();

//         const response = await axios.post(
//             `${DARAJA_BASE_URL}/mpesa/c2b/v1/registerurl`,
//             {
//                 ShortCode: SHORTCODE,
//                 ResponseType: "Completed",
//                 ConfirmationURL: "https://c2bconfirmation-5c3kidf73q-uc.a.run.app",
//                 ValidationURL: "https://c2bvalidation-5c3kidf73q-uc.a.run.app",
//             },
//             { headers: { Authorization: `Bearer ${token}` } }
//         );

//         res.status(200).json(response.data);
//     } catch (error: any) {
//         res.status(500).json(error.response?.data ?? error.message);
//     }
// });

// ── 4. C2B Validation — Safaricom checks before completing payment ─────────
export const c2bValidation = functions.https.onRequest(async (req, res) => {
    // Accept all payments in sandbox
    res.status(200).json({ ResultCode: 0, ResultDesc: "Accepted" });
});

// ── 5. C2B Confirmation — payment completed, write to Firestore ───────────
export const c2bConfirmation = functions.https.onRequest(async (req, res) => {
    const data = req.body;

    try {
        const phone = data.MSISDN;
        const amount = data.TransAmount;
        const mpesaCode = data.TransID;
        const accountRef = data.BillRefNumber; // tenant's account reference (phone/unit)
        const firstName = data.FirstName ?? "";

        // Try to match tenant by phone number
        const tenantSnap = await db
            .collection("tenants")
            .where("phone", "==", phone)
            .limit(1)
            .get();

        const isMatched = !tenantSnap.empty;
        const tenantData = isMatched ? tenantSnap.docs[0].data() : null;

        // Write to finances collection
        await db.collection("finances").add({
            type: "payment",
            amount: parseFloat(amount),
            mpesaCode,
            phone,
            accountRef,
            tenantId: tenantData?.tenantId ?? null,
            tenantName: tenantData?.name ?? firstName,
            unitName: tenantData?.unitName ?? accountRef,
            propertyId: tenantData?.propertyId ?? null,
            description: `C2B Paybill payment — ${accountRef}`,
            status: isMatched ? "matched" : "unmatched",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        res.status(200).json({ ResultCode: 0, ResultDesc: "Accepted" });

    } catch (error) {
        console.error("C2B confirmation error:", error);
        res.status(200).json({ ResultCode: 0, ResultDesc: "Accepted" }); // Always 200 to Safaricom
    }
});