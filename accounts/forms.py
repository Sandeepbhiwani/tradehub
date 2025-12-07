from django import forms
from django.contrib.auth.forms import UserCreationForm
from .models import CustomUser

class CustomUserCreationForm(UserCreationForm):
    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(attrs={
            'class': 'w-full px-4 py-3 bg-cyber-dark border border-gray-700 rounded-lg focus:outline-none focus:border-cyber-primary transition-colors text-white placeholder-gray-500',
            'placeholder': 'Enter your email'
        })
    )

    class Meta:
        model = CustomUser
        fields = ('username', 'email', 'password1', 'password2')

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Style all fields consistently
        for field_name in self.fields:
            self.fields[field_name].widget.attrs.update({
                'class': 'w-full px-4 py-3 bg-cyber-dark border border-gray-700 rounded-lg focus:outline-none focus:border-cyber-primary transition-colors text-white placeholder-gray-500',
                'placeholder': f'Enter your {field_name}'
            })
