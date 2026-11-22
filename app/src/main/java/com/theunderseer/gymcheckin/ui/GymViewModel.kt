package com.theunderseer.gymcheckin.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.theunderseer.gymcheckin.domain.model.Member
import com.theunderseer.gymcheckin.domain.model.MembershipPlan
import com.theunderseer.gymcheckin.domain.model.MembershipStatus
import com.theunderseer.gymcheckin.domain.repository.GymRepository
import com.theunderseer.gymcheckin.domain.util.currentDate
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface CheckResult {
    data class Found(val member: Member, val status: MembershipStatus) : CheckResult
    data class NotFound(val searchedId: String) : CheckResult
}

data class GymUiState(
    // Registration
    val registrationName: String = "",
    val selectedPlan: MembershipPlan = MembershipPlan.ONE_MONTH,
    val registrationError: String? = null,
    val isRegistering: Boolean = false,
    val registeredMember: Member? = null,

    // Check
    val checkInputId: String = "",
    val isChecking: Boolean = false,
    val checkResult: CheckResult? = null
)

class GymViewModel(
    private val repository: GymRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(GymUiState())
    val uiState: StateFlow<GymUiState> = _uiState.asStateFlow()

    fun onRegistrationNameChange(newName: String) {
        _uiState.value = _uiState.value.copy(
            registrationName = newName,
            registrationError = null
        )
    }

    fun onPlanSelected(plan: MembershipPlan) {
        _uiState.value = _uiState.value.copy(selectedPlan = plan)
    }

    fun registerMember(onSuccess: (Member) -> Unit) {
        val trimmed = _uiState.value.registrationName.trim()
        if (trimmed.isEmpty()) {
            _uiState.value = _uiState.value.copy(registrationError = "Name cannot be empty")
            return
        }

        val plan = _uiState.value.selectedPlan
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRegistering = true, registrationError = null)
            try {
                val member = repository.registerMember(name = trimmed, plan = plan)
                _uiState.value = _uiState.value.copy(
                    isRegistering = false,
                    registrationName = "",
                    selectedPlan = MembershipPlan.ONE_MONTH,
                    registeredMember = member
                )
                onSuccess(member)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isRegistering = false,
                    registrationError = e.message ?: "Failed to register member"
                )
            }
        }
    }

    fun onCheckInputIdChange(newId: String) {
        _uiState.value = _uiState.value.copy(checkInputId = newId)
    }

    fun checkMember(id: String? = null) {
        val targetId = (id ?: _uiState.value.checkInputId).trim()
        if (targetId.isEmpty()) return

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isChecking = true, checkInputId = targetId)
            val member = repository.getMemberById(targetId)
            if (member != null) {
                val status = member.status(currentDate())
                _uiState.value = _uiState.value.copy(
                    isChecking = false,
                    checkResult = CheckResult.Found(member, status)
                )
            } else {
                _uiState.value = _uiState.value.copy(
                    isChecking = false,
                    checkResult = CheckResult.NotFound(targetId)
                )
            }
        }
    }

    fun clearCheckResult() {
        _uiState.value = _uiState.value.copy(
            checkInputId = "",
            checkResult = null
        )
    }

    companion object {
        fun provideFactory(repository: GymRepository): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    return GymViewModel(repository) as T
                }
            }
    }
}
