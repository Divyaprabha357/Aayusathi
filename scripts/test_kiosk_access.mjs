const apiKey = 'AIzaSyCMJ0DhDzWRA3sMA_nqGSgNOJ_LIPWH8No';
const projectId = 'aayusathi-a1199';

async function testKioskAccess() {
  console.log('Signing in anonymously as Kiosk client...');
  const authRes = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ returnSecureToken: true })
  });

  const authData = await authRes.json();
  const token = authData.idToken;
  console.log('Signed in anonymously, token received.');

  // Test GET single doc /demo_aadhaar/111111111111
  console.log('Testing GET /demo_aadhaar/111111111111...');
  const docRes = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/demo_aadhaar/111111111111`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });

  console.log('GET 111111111111 HTTP Status:', docRes.status);
  const docData = await docRes.json();
  console.log('Document fields:', JSON.stringify(docData.fields, null, 2));

  // Test list /demo_aadhaar (should be forbidden to anonymous Kiosk, allowed only to admin)
  console.log('\nTesting LIST /demo_aadhaar (expected 403 for anonymous kiosk)...');
  const listRes = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/demo_aadhaar`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log('LIST HTTP Status:', listRes.status, '(403 Forbidden is correct according to security rules)');
}

testKioskAccess().catch(console.error);
