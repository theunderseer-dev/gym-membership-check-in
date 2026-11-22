package com.theunderseer.gymcheckin.ui

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.theunderseer.gymcheckin.domain.model.MembershipStatus
import com.theunderseer.gymcheckin.qr.ImageDecodeResult
import com.theunderseer.gymcheckin.qr.QrCodeUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheckMembershipScreen(
    uiState: GymUiState,
    onIdChange: (String) -> Unit,
    onCheckClick: (id: String?) -> Unit,
    onClearResult: () -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val focusManager = LocalFocusManager.current
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }
    var imageScanError by remember { mutableStateOf<String?>(null) }

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        if (uri == null) {
            // Cancelled: return to check screen without error
            return@rememberLauncherForActivityResult
        }
        imageScanError = null
        when (val result = QrCodeUtils.decodeQrFromUri(context, uri)) {
            is ImageDecodeResult.Success -> {
                onCheckClick(result.text)
            }
            is ImageDecodeResult.NoQrFound -> {
                imageScanError = "No QR code found"
                Toast.makeText(context, "No QR code found", Toast.LENGTH_SHORT).show()
            }
            is ImageDecodeResult.Error -> {
                imageScanError = "Could not read image"
                Toast.makeText(context, "Could not read image", Toast.LENGTH_SHORT).show()
            }
        }
    }

    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
        )
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        hasCameraPermission = isGranted
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Check Membership", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        },
        modifier = modifier
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // If result is displayed
            if (uiState.checkResult != null) {
                CheckResultView(
                    result = uiState.checkResult,
                    onCheckAnother = {
                        imageScanError = null
                        onClearResult()
                    },
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp)
                )
            } else {
                // Persistent "Scan QR from image" button (works independently of camera/permission)
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 12.dp)
                ) {
                    Button(
                        onClick = {
                            imageScanError = null
                            imagePickerLauncher.launch(arrayOf("image/*"))
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.secondary
                        )
                    ) {
                        Icon(imageVector = Icons.Default.Search, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Scan QR from image",
                            style = MaterialTheme.typography.titleMedium
                        )
                    }

                    if (imageScanError != null) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.errorContainer
                            ),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 12.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Warning,
                                    contentDescription = "Error",
                                    tint = MaterialTheme.colorScheme.error,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = imageScanError!!,
                                    color = MaterialTheme.colorScheme.onErrorContainer,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium,
                                    modifier = Modifier.weight(1f)
                                )
                                IconButton(
                                    onClick = { imageScanError = null },
                                    modifier = Modifier.size(24.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Close,
                                        contentDescription = "Dismiss",
                                        tint = MaterialTheme.colorScheme.onErrorContainer,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }
                        }
                    }
                }

                // Tabs: 0 = Scan Camera, 1 = Manual ID
                TabRow(selectedTabIndex = selectedTab) {
                    Tab(
                        selected = selectedTab == 0,
                        onClick = { selectedTab = 0 },
                        text = { Text("Scan QR") }
                    )
                    Tab(
                        selected = selectedTab == 1,
                        onClick = { selectedTab = 1 },
                        text = { Text("Enter ID") }
                    )
                }

                if (selectedTab == 0) {
                    // Camera Scanner Tab
                    if (hasCameraPermission) {
                        Box(modifier = Modifier.fillMaxSize()) {
                            CameraScannerView(
                                onQrScanned = { scannedId ->
                                    onCheckClick(scannedId)
                                },
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                    } else {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(32.dp),
                            verticalArrangement = Arrangement.Center,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.Warning,
                                contentDescription = "Camera Permission",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(64.dp)
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = "Camera Permission Required",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "To scan client QR passes directly, please grant camera access.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(24.dp))
                            Button(
                                onClick = {
                                    permissionLauncher.launch(Manifest.permission.CAMERA)
                                }
                            ) {
                                Text("Grant Permission")
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                            Button(
                                onClick = {
                                    imageScanError = null
                                    imagePickerLauncher.launch(arrayOf("image/*"))
                                }
                            ) {
                                Text("Scan QR from image")
                            }
                            Spacer(modifier = Modifier.height(12.dp))
                            OutlinedButton(onClick = { selectedTab = 1 }) {
                                Text("Use Manual ID Entry Instead")
                            }
                        }
                    }
                } else {
                    // Manual ID Entry Tab
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = "Manual ID Verification",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Enter or paste the client's unique member ID",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Spacer(modifier = Modifier.height(24.dp))

                        OutlinedTextField(
                            value = uiState.checkInputId,
                            onValueChange = onIdChange,
                            label = { Text("Member ID") },
                            placeholder = { Text("e.g. K7X-9M2") },
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(
                                capitalization = androidx.compose.ui.text.input.KeyboardCapitalization.Characters,
                                imeAction = ImeAction.Search
                            ),
                            keyboardActions = KeyboardActions(onSearch = {
                                focusManager.clearFocus()
                                onCheckClick(null)
                            }),
                            trailingIcon = {
                                if (uiState.checkInputId.isNotEmpty()) {
                                    IconButton(onClick = { onIdChange("") }) {
                                        Icon(imageVector = Icons.Default.Close, contentDescription = "Clear")
                                    }
                                }
                            },
                            modifier = Modifier.fillMaxWidth()
                        )

                        Spacer(modifier = Modifier.height(24.dp))

                        Button(
                            onClick = {
                                focusManager.clearFocus()
                                onCheckClick(null)
                            },
                            enabled = !uiState.isChecking && uiState.checkInputId.isNotBlank(),
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp)
                        ) {
                            if (uiState.isChecking) {
                                CircularProgressIndicator(
                                    color = MaterialTheme.colorScheme.onPrimary,
                                    modifier = Modifier.height(24.dp)
                                )
                            } else {
                                Icon(imageVector = Icons.Default.Search, contentDescription = "Check")
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Check", style = MaterialTheme.typography.titleMedium)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun CheckResultView(
    result: CheckResult,
    onCheckAnother: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        when (result) {
            is CheckResult.Found -> {
                val isActive = result.status == MembershipStatus.ACTIVE
                val statusColor = if (isActive) Color(0xFF2E7D32) else Color(0xFFC62828)
                val statusBg = if (isActive) Color(0xFFE8F5E9) else Color(0xFFFFEBEE)

                Icon(
                    imageVector = if (isActive) Icons.Default.CheckCircle else Icons.Default.Warning,
                    contentDescription = result.status.name,
                    tint = statusColor,
                    modifier = Modifier.size(64.dp)
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Status Pill Badge
                Box(
                    modifier = Modifier
                        .background(statusBg, RoundedCornerShape(50))
                        .padding(horizontal = 24.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = if (isActive) "ACTIVE" else "EXPIRED",
                        color = statusColor,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(20.dp)
                    ) {
                        Text(
                            text = "Client Name:",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = result.member.name,
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Text(
                            text = "Valid Through (Inclusive):",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = result.member.endsOnInclusive.toString(),
                            style = MaterialTheme.typography.titleMedium,
                            color = statusColor,
                            fontWeight = FontWeight.Bold
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Text(
                            text = "Member ID:",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = result.member.id,
                            style = MaterialTheme.typography.bodySmall,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                }
            }
            is CheckResult.NotFound -> {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Not Found",
                    tint = Color(0xFFC62828),
                    modifier = Modifier.size(64.dp)
                )

                Spacer(modifier = Modifier.height(16.dp))

                Box(
                    modifier = Modifier
                        .background(Color(0xFFFFEBEE), RoundedCornerShape(50))
                        .padding(horizontal = 24.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = "NOT FOUND",
                        color = Color(0xFFC62828),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.height(20.dp))

                Text(
                    text = "No member found with ID:",
                    style = MaterialTheme.typography.bodyLarge
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = result.searchedId,
                    style = MaterialTheme.typography.bodyMedium,
                    fontFamily = FontFamily.Monospace,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.error
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        Button(
            onClick = onCheckAnother,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
        ) {
            Text("Check Another Member", style = MaterialTheme.typography.titleMedium)
        }
    }
}
