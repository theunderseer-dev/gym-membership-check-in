package com.theunderseer.gymcheckin

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.theunderseer.gymcheckin.model.Member
import com.theunderseer.gymcheckin.ui.CheckMembershipScreen
import com.theunderseer.gymcheckin.ui.GymViewModel
import com.theunderseer.gymcheckin.ui.HomeScreen
import com.theunderseer.gymcheckin.ui.RegisterMemberScreen
import com.theunderseer.gymcheckin.ui.RegistrationSuccessScreen

enum class AppScreen {
    HOME,
    REGISTER,
    REGISTRATION_SUCCESS,
    CHECK
}

class MainActivity : ComponentActivity() {

    private val viewModel: GymViewModel by viewModels {
        val app = application as GymCheckInApplication
        GymViewModel.provideFactory(app.container.gymRepository)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    GymApp(viewModel = viewModel)
                }
            }
        }
    }
}

@Composable
fun GymApp(viewModel: GymViewModel) {
    val uiState by viewModel.uiState.collectAsState()
    var currentScreen by rememberSaveable { mutableStateOf(AppScreen.HOME) }

    BackHandler(enabled = currentScreen != AppScreen.HOME) {
        if (currentScreen == AppScreen.CHECK) {
            viewModel.clearCheckResult()
        }
        currentScreen = AppScreen.HOME
    }

    when (currentScreen) {
        AppScreen.HOME -> {
            HomeScreen(
                onNavigateToRegister = {
                    currentScreen = AppScreen.REGISTER
                },
                onNavigateToCheck = {
                    viewModel.clearCheckResult()
                    currentScreen = AppScreen.CHECK
                }
            )
        }
        AppScreen.REGISTER -> {
            RegisterMemberScreen(
                uiState = uiState,
                onNameChange = viewModel::onRegistrationNameChange,
                onRegisterClick = { onSuccess ->
                    viewModel.registerMember { member ->
                        onSuccess(member)
                    }
                },
                onRegistrationSuccess = {
                    currentScreen = AppScreen.REGISTRATION_SUCCESS
                },
                onNavigateBack = {
                    currentScreen = AppScreen.HOME
                }
            )
        }
        AppScreen.REGISTRATION_SUCCESS -> {
            val member = uiState.registeredMember
            if (member != null) {
                RegistrationSuccessScreen(
                    member = member,
                    onNavigateHome = {
                        currentScreen = AppScreen.HOME
                    }
                )
            } else {
                currentScreen = AppScreen.HOME
            }
        }
        AppScreen.CHECK -> {
            CheckMembershipScreen(
                uiState = uiState,
                onIdChange = viewModel::onCheckInputIdChange,
                onCheckClick = { id ->
                    viewModel.checkMember(id)
                },
                onClearResult = {
                    viewModel.clearCheckResult()
                },
                onNavigateBack = {
                    viewModel.clearCheckResult()
                    currentScreen = AppScreen.HOME
                }
            )
        }
    }
}
