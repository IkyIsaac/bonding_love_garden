export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      access_plan_items: {
        Row: {
          access_plan_id: string
          catalog_item_id: string
        }
        Insert: {
          access_plan_id: string
          catalog_item_id: string
        }
        Update: {
          access_plan_id?: string
          catalog_item_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "access_plan_items_access_plan_id_fkey"
            columns: ["access_plan_id"]
            isOneToOne: false
            referencedRelation: "access_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "access_plan_items_catalog_item_id_fkey"
            columns: ["catalog_item_id"]
            isOneToOne: false
            referencedRelation: "catalog_items"
            referencedColumns: ["id"]
          },
        ]
      }
      access_plans: {
        Row: {
          created_at: string
          daily_time_limit_minutes: number | null
          description: string | null
          id: string
          is_active: boolean
          name: string
          plan_type: string
          price: number
          updated_at: string
          validity_unit: string
          validity_value: number
          visit_limit: number | null
        }
        Insert: {
          created_at?: string
          daily_time_limit_minutes?: number | null
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          plan_type: string
          price: number
          updated_at?: string
          validity_unit: string
          validity_value: number
          visit_limit?: number | null
        }
        Update: {
          created_at?: string
          daily_time_limit_minutes?: number | null
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          plan_type?: string
          price?: number
          updated_at?: string
          validity_unit?: string
          validity_value?: number
          visit_limit?: number | null
        }
        Relationships: []
      }
      audit_log: {
        Row: {
          action_type: string
          actor_profile_id: string | null
          created_at: string
          details: string | null
          id: string
          location: string | null
          status: string
          target_id: string | null
          target_type: string | null
        }
        Insert: {
          action_type: string
          actor_profile_id?: string | null
          created_at?: string
          details?: string | null
          id?: string
          location?: string | null
          status?: string
          target_id?: string | null
          target_type?: string | null
        }
        Update: {
          action_type?: string
          actor_profile_id?: string | null
          created_at?: string
          details?: string | null
          id?: string
          location?: string | null
          status?: string
          target_id?: string | null
          target_type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_log_actor_profile_id_fkey"
            columns: ["actor_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      catalog_items: {
        Row: {
          created_at: string
          description: string | null
          id: string
          image_url: string | null
          is_active: boolean
          is_motorized: boolean | null
          name: string
          price: number
          pricing_unit: string
          type: string
          updated_at: string
          zone_id: string | null
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_motorized?: boolean | null
          name: string
          price: number
          pricing_unit?: string
          type: string
          updated_at?: string
          zone_id?: string | null
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_motorized?: boolean | null
          name?: string
          price?: number
          pricing_unit?: string
          type?: string
          updated_at?: string
          zone_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "catalog_items_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      discount_rule_components: {
        Row: {
          catalog_item_id: string | null
          discount_rule_id: string
          id: string
          is_entry_fee: boolean
        }
        Insert: {
          catalog_item_id?: string | null
          discount_rule_id: string
          id?: string
          is_entry_fee?: boolean
        }
        Update: {
          catalog_item_id?: string | null
          discount_rule_id?: string
          id?: string
          is_entry_fee?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "discount_rule_components_catalog_item_id_fkey"
            columns: ["catalog_item_id"]
            isOneToOne: false
            referencedRelation: "catalog_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "discount_rule_components_discount_rule_id_fkey"
            columns: ["discount_rule_id"]
            isOneToOne: false
            referencedRelation: "discount_rules"
            referencedColumns: ["id"]
          },
        ]
      }
      discount_rules: {
        Row: {
          created_at: string
          days_of_week: number[] | null
          description: string | null
          discount_type: string
          discount_value: number
          id: string
          min_quantity: number | null
          name: string
          status: string
          updated_at: string
          valid_from: string | null
          valid_to: string | null
        }
        Insert: {
          created_at?: string
          days_of_week?: number[] | null
          description?: string | null
          discount_type: string
          discount_value: number
          id?: string
          min_quantity?: number | null
          name: string
          status?: string
          updated_at?: string
          valid_from?: string | null
          valid_to?: string | null
        }
        Update: {
          created_at?: string
          days_of_week?: number[] | null
          description?: string | null
          discount_type?: string
          discount_value?: number
          id?: string
          min_quantity?: number | null
          name?: string
          status?: string
          updated_at?: string
          valid_from?: string | null
          valid_to?: string | null
        }
        Relationships: []
      }
      entry_fee_config: {
        Row: {
          amount: number
          created_by: string | null
          effective_from: string
          effective_to: string | null
          id: string
        }
        Insert: {
          amount: number
          created_by?: string | null
          effective_from?: string
          effective_to?: string | null
          id?: string
        }
        Update: {
          amount?: number
          created_by?: string | null
          effective_from?: string
          effective_to?: string | null
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "entry_fee_config_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      families: {
        Row: {
          created_at: string
          display_name: string | null
          id: string
          owner_profile_id: string
        }
        Insert: {
          created_at?: string
          display_name?: string | null
          id?: string
          owner_profile_id: string
        }
        Update: {
          created_at?: string
          display_name?: string | null
          id?: string
          owner_profile_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "families_owner_profile_id_fkey"
            columns: ["owner_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      family_members: {
        Row: {
          age: number | null
          allergies_notes: string | null
          created_at: string
          family_id: string
          full_name: string
          gender: string | null
          general_notes: string | null
          id: string
          is_primary_child: boolean
          kind: string
          photo_url: string | null
          updated_at: string
        }
        Insert: {
          age?: number | null
          allergies_notes?: string | null
          created_at?: string
          family_id: string
          full_name: string
          gender?: string | null
          general_notes?: string | null
          id?: string
          is_primary_child?: boolean
          kind: string
          photo_url?: string | null
          updated_at?: string
        }
        Update: {
          age?: number | null
          allergies_notes?: string | null
          created_at?: string
          family_id?: string
          full_name?: string
          gender?: string | null
          general_notes?: string | null
          id?: string
          is_primary_child?: boolean
          kind?: string
          photo_url?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "family_members_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      game_credit_ledger: {
        Row: {
          amount: number
          created_at: string
          created_by: string | null
          direction: string
          family_id: string
          family_member_id: string | null
          id: string
          order_id: string | null
          reason: string | null
          wristband_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          created_by?: string | null
          direction: string
          family_id: string
          family_member_id?: string | null
          id?: string
          order_id?: string | null
          reason?: string | null
          wristband_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          created_by?: string | null
          direction?: string
          family_id?: string
          family_member_id?: string | null
          id?: string
          order_id?: string | null
          reason?: string | null
          wristband_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "game_credit_ledger_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_credit_ledger_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_credit_ledger_family_member_id_fkey"
            columns: ["family_member_id"]
            isOneToOne: false
            referencedRelation: "family_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_credit_ledger_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_credit_ledger_wristband_id_fkey"
            columns: ["wristband_id"]
            isOneToOne: false
            referencedRelation: "wristband_live_status"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_credit_ledger_wristband_id_fkey"
            columns: ["wristband_id"]
            isOneToOne: false
            referencedRelation: "wristbands"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body: string | null
          created_at: string
          id: string
          is_read: boolean
          payload: Json | null
          recipient_profile_id: string
          title: string
          type: string
        }
        Insert: {
          body?: string | null
          created_at?: string
          id?: string
          is_read?: boolean
          payload?: Json | null
          recipient_profile_id: string
          title: string
          type: string
        }
        Update: {
          body?: string | null
          created_at?: string
          id?: string
          is_read?: boolean
          payload?: Json | null
          recipient_profile_id?: string
          title?: string
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_recipient_profile_id_fkey"
            columns: ["recipient_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      order_discount_applications: {
        Row: {
          amount_deducted: number
          discount_rule_id: string
          order_id: string
        }
        Insert: {
          amount_deducted: number
          discount_rule_id: string
          order_id: string
        }
        Update: {
          amount_deducted?: number
          discount_rule_id?: string
          order_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "order_discount_applications_discount_rule_id_fkey"
            columns: ["discount_rule_id"]
            isOneToOne: false
            referencedRelation: "discount_rules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_discount_applications_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          created_at: string
          family_member_id: string | null
          guest_name: string | null
          id: string
          item_type: string
          line_total: number
          order_id: string
          quantity: number
          reference_id: string | null
          unit_price: number
        }
        Insert: {
          created_at?: string
          family_member_id?: string | null
          guest_name?: string | null
          id?: string
          item_type: string
          line_total: number
          order_id: string
          quantity?: number
          reference_id?: string | null
          unit_price: number
        }
        Update: {
          created_at?: string
          family_member_id?: string | null
          guest_name?: string | null
          id?: string
          item_type?: string
          line_total?: number
          order_id?: string
          quantity?: number
          reference_id?: string | null
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_family_member_id_fkey"
            columns: ["family_member_id"]
            isOneToOne: false
            referencedRelation: "family_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          buyer_profile_id: string
          channel: string
          created_at: string
          discount_total: number
          entry_fee_total: number
          family_id: string
          id: string
          status: string
          subtotal: number
          total_amount: number
          updated_at: string
        }
        Insert: {
          buyer_profile_id: string
          channel: string
          created_at?: string
          discount_total?: number
          entry_fee_total?: number
          family_id: string
          id?: string
          status?: string
          subtotal: number
          total_amount: number
          updated_at?: string
        }
        Update: {
          buyer_profile_id?: string
          channel?: string
          created_at?: string
          discount_total?: number
          entry_fee_total?: number
          family_id?: string
          id?: string
          status?: string
          subtotal?: number
          total_amount?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_buyer_profile_id_fkey"
            columns: ["buyer_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      package_items: {
        Row: {
          catalog_item_id: string
          package_id: string
          quantity: number
        }
        Insert: {
          catalog_item_id: string
          package_id: string
          quantity?: number
        }
        Update: {
          catalog_item_id?: string
          package_id?: string
          quantity?: number
        }
        Relationships: [
          {
            foreignKeyName: "package_items_catalog_item_id_fkey"
            columns: ["catalog_item_id"]
            isOneToOne: false
            referencedRelation: "catalog_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "package_items_package_id_fkey"
            columns: ["package_id"]
            isOneToOne: false
            referencedRelation: "packages"
            referencedColumns: ["id"]
          },
        ]
      }
      packages: {
        Row: {
          availability_end: string | null
          availability_start: string | null
          created_at: string
          description: string | null
          id: string
          image_url: string | null
          is_active: boolean
          name: string
          price: number
          updated_at: string
        }
        Insert: {
          availability_end?: string | null
          availability_start?: string | null
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          name: string
          price: number
          updated_at?: string
        }
        Update: {
          availability_end?: string | null
          availability_start?: string | null
          created_at?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          name?: string
          price?: number
          updated_at?: string
        }
        Relationships: []
      }
      payment_providers: {
        Row: {
          code: string
          created_at: string
          display_name: string
          id: string
          is_active: boolean
          public_config: Json | null
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          display_name: string
          id?: string
          is_active?: boolean
          public_config?: Json | null
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          display_name?: string
          id?: string
          is_active?: boolean
          public_config?: Json | null
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      payment_webhook_events: {
        Row: {
          created_at: string
          event_type: string | null
          id: string
          payload: Json
          payment_id: string | null
          processed_at: string | null
          provider_id: string | null
          signature_verified: boolean
        }
        Insert: {
          created_at?: string
          event_type?: string | null
          id?: string
          payload: Json
          payment_id?: string | null
          processed_at?: string | null
          provider_id?: string | null
          signature_verified: boolean
        }
        Update: {
          created_at?: string
          event_type?: string | null
          id?: string
          payload?: Json
          payment_id?: string | null
          processed_at?: string | null
          provider_id?: string | null
          signature_verified?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "payment_webhook_events_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_webhook_events_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "payment_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          created_at: string
          id: string
          order_id: string
          provider_id: string
          provider_reference: string | null
          status: string
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          order_id: string
          provider_id: string
          provider_reference?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          order_id?: string
          provider_id?: string
          provider_reference?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payments_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "payment_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          approval_status: string
          created_at: string
          full_name: string
          id: string
          phone: string
          photo_url: string | null
          role: string
          updated_at: string
        }
        Insert: {
          approval_status?: string
          created_at?: string
          full_name?: string
          id: string
          phone: string
          photo_url?: string | null
          role: string
          updated_at?: string
        }
        Update: {
          approval_status?: string
          created_at?: string
          full_name?: string
          id?: string
          phone?: string
          photo_url?: string | null
          role?: string
          updated_at?: string
        }
        Relationships: []
      }
      reservation_settings: {
        Row: {
          default_fee: number
          id: string
          max_advance_days: number
          max_per_day_per_family: number | null
          singleton: boolean
          updated_at: string
        }
        Insert: {
          default_fee?: number
          id?: string
          max_advance_days?: number
          max_per_day_per_family?: number | null
          singleton?: boolean
          updated_at?: string
        }
        Update: {
          default_fee?: number
          id?: string
          max_advance_days?: number
          max_per_day_per_family?: number | null
          singleton?: boolean
          updated_at?: string
        }
        Relationships: []
      }
      reservations: {
        Row: {
          catalog_item_id: string
          created_at: string
          fee: number
          id: string
          slot_end: string
          slot_start: string
          status: string
          subscription_id: string
          updated_at: string
        }
        Insert: {
          catalog_item_id: string
          created_at?: string
          fee?: number
          id?: string
          slot_end: string
          slot_start: string
          status?: string
          subscription_id: string
          updated_at?: string
        }
        Update: {
          catalog_item_id?: string
          created_at?: string
          fee?: number
          id?: string
          slot_end?: string
          slot_start?: string
          status?: string
          subscription_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "reservations_catalog_item_id_fkey"
            columns: ["catalog_item_id"]
            isOneToOne: false
            referencedRelation: "catalog_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reservations_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "subscriptions"
            referencedColumns: ["id"]
          },
        ]
      }
      sessions: {
        Row: {
          catalog_item_id: string | null
          created_at: string
          ended_at: string | null
          extended_minutes_total: number
          id: string
          planned_end_at: string
          started_at: string
          updated_at: string
          wristband_id: string
          zone_id: string | null
        }
        Insert: {
          catalog_item_id?: string | null
          created_at?: string
          ended_at?: string | null
          extended_minutes_total?: number
          id?: string
          planned_end_at: string
          started_at?: string
          updated_at?: string
          wristband_id: string
          zone_id?: string | null
        }
        Update: {
          catalog_item_id?: string | null
          created_at?: string
          ended_at?: string | null
          extended_minutes_total?: number
          id?: string
          planned_end_at?: string
          started_at?: string
          updated_at?: string
          wristband_id?: string
          zone_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "sessions_catalog_item_id_fkey"
            columns: ["catalog_item_id"]
            isOneToOne: false
            referencedRelation: "catalog_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sessions_wristband_id_fkey"
            columns: ["wristband_id"]
            isOneToOne: false
            referencedRelation: "wristband_live_status"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sessions_wristband_id_fkey"
            columns: ["wristband_id"]
            isOneToOne: false
            referencedRelation: "wristbands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sessions_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      subscriptions: {
        Row: {
          access_plan_id: string
          created_at: string
          ends_at: string
          entry_fee_config_id: string | null
          family_id: string
          family_member_id: string | null
          id: string
          starts_at: string
          status: string
          updated_at: string
          visits_remaining: number | null
        }
        Insert: {
          access_plan_id: string
          created_at?: string
          ends_at: string
          entry_fee_config_id?: string | null
          family_id: string
          family_member_id?: string | null
          id?: string
          starts_at: string
          status?: string
          updated_at?: string
          visits_remaining?: number | null
        }
        Update: {
          access_plan_id?: string
          created_at?: string
          ends_at?: string
          entry_fee_config_id?: string | null
          family_id?: string
          family_member_id?: string | null
          id?: string
          starts_at?: string
          status?: string
          updated_at?: string
          visits_remaining?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_access_plan_id_fkey"
            columns: ["access_plan_id"]
            isOneToOne: false
            referencedRelation: "access_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscriptions_entry_fee_config_id_fkey"
            columns: ["entry_fee_config_id"]
            isOneToOne: false
            referencedRelation: "entry_fee_config"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscriptions_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subscriptions_family_member_id_fkey"
            columns: ["family_member_id"]
            isOneToOne: false
            referencedRelation: "family_members"
            referencedColumns: ["id"]
          },
        ]
      }
      venue_settings: {
        Row: {
          brand_colors: Json | null
          contact_info: Json | null
          currency: string
          id: string
          logo_url: string | null
          park_name: string
          singleton: boolean
          timezone: string
          updated_at: string
        }
        Insert: {
          brand_colors?: Json | null
          contact_info?: Json | null
          currency?: string
          id?: string
          logo_url?: string | null
          park_name: string
          singleton?: boolean
          timezone?: string
          updated_at?: string
        }
        Update: {
          brand_colors?: Json | null
          contact_info?: Json | null
          currency?: string
          id?: string
          logo_url?: string | null
          park_name?: string
          singleton?: boolean
          timezone?: string
          updated_at?: string
        }
        Relationships: []
      }
      wristbands: {
        Row: {
          expires_at: string
          family_id: string
          family_member_id: string | null
          id: string
          issued_at: string
          issued_by: string | null
          last_scanned_at: string | null
          qr_code_value: string
          status: string
          subscription_id: string | null
          updated_at: string
          wristband_number: string
        }
        Insert: {
          expires_at: string
          family_id: string
          family_member_id?: string | null
          id?: string
          issued_at?: string
          issued_by?: string | null
          last_scanned_at?: string | null
          qr_code_value: string
          status?: string
          subscription_id?: string | null
          updated_at?: string
          wristband_number: string
        }
        Update: {
          expires_at?: string
          family_id?: string
          family_member_id?: string | null
          id?: string
          issued_at?: string
          issued_by?: string | null
          last_scanned_at?: string | null
          qr_code_value?: string
          status?: string
          subscription_id?: string | null
          updated_at?: string
          wristband_number?: string
        }
        Relationships: [
          {
            foreignKeyName: "wristbands_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wristbands_family_member_id_fkey"
            columns: ["family_member_id"]
            isOneToOne: false
            referencedRelation: "family_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wristbands_issued_by_fkey"
            columns: ["issued_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wristbands_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "subscriptions"
            referencedColumns: ["id"]
          },
        ]
      }
      zones: {
        Row: {
          capacity: number | null
          id: string
          is_active: boolean
          name: string
        }
        Insert: {
          capacity?: number | null
          id?: string
          is_active?: boolean
          name: string
        }
        Update: {
          capacity?: number | null
          id?: string
          is_active?: boolean
          name?: string
        }
        Relationships: []
      }
    }
    Views: {
      family_credit_balance: {
        Row: {
          balance: number | null
          family_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "game_credit_ledger_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      session_live_status: {
        Row: {
          catalog_item_id: string | null
          created_at: string | null
          ended_at: string | null
          extended_minutes_total: number | null
          id: string | null
          planned_end_at: string | null
          started_at: string | null
          status: string | null
          updated_at: string | null
          wristband_id: string | null
          zone_id: string | null
        }
        Insert: {
          catalog_item_id?: string | null
          created_at?: string | null
          ended_at?: string | null
          extended_minutes_total?: number | null
          id?: string | null
          planned_end_at?: string | null
          started_at?: string | null
          status?: never
          updated_at?: string | null
          wristband_id?: string | null
          zone_id?: string | null
        }
        Update: {
          catalog_item_id?: string | null
          created_at?: string | null
          ended_at?: string | null
          extended_minutes_total?: number | null
          id?: string | null
          planned_end_at?: string | null
          started_at?: string | null
          status?: never
          updated_at?: string | null
          wristband_id?: string | null
          zone_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "sessions_catalog_item_id_fkey"
            columns: ["catalog_item_id"]
            isOneToOne: false
            referencedRelation: "catalog_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sessions_wristband_id_fkey"
            columns: ["wristband_id"]
            isOneToOne: false
            referencedRelation: "wristband_live_status"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sessions_wristband_id_fkey"
            columns: ["wristband_id"]
            isOneToOne: false
            referencedRelation: "wristbands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sessions_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      wristband_live_status: {
        Row: {
          expires_at: string | null
          family_id: string | null
          family_member_id: string | null
          id: string | null
          issued_at: string | null
          issued_by: string | null
          last_scanned_at: string | null
          live_status: string | null
          qr_code_value: string | null
          status: string | null
          subscription_id: string | null
          updated_at: string | null
          wristband_number: string | null
        }
        Insert: {
          expires_at?: string | null
          family_id?: string | null
          family_member_id?: string | null
          id?: string | null
          issued_at?: string | null
          issued_by?: string | null
          last_scanned_at?: string | null
          live_status?: never
          qr_code_value?: string | null
          status?: string | null
          subscription_id?: string | null
          updated_at?: string | null
          wristband_number?: string | null
        }
        Update: {
          expires_at?: string | null
          family_id?: string | null
          family_member_id?: string | null
          id?: string | null
          issued_at?: string | null
          issued_by?: string | null
          last_scanned_at?: string | null
          live_status?: never
          qr_code_value?: string | null
          status?: string | null
          subscription_id?: string | null
          updated_at?: string | null
          wristband_number?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "wristbands_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wristbands_family_member_id_fkey"
            columns: ["family_member_id"]
            isOneToOne: false
            referencedRelation: "family_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wristbands_issued_by_fkey"
            columns: ["issued_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wristbands_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "subscriptions"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      is_admin: { Args: never; Returns: boolean }
      is_staff: { Args: never; Returns: boolean }
      is_supervisor: { Args: never; Returns: boolean }
      owns_family: { Args: { fid: string }; Returns: boolean }
      owns_order: { Args: { oid: string }; Returns: boolean }
      owns_subscription: { Args: { sid: string }; Returns: boolean }
      owns_wristband: { Args: { wid: string }; Returns: boolean }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const

