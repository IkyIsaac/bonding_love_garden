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
      [_ in never]: never
    }
    Functions: {
      is_admin: { Args: never; Returns: boolean }
      is_staff: { Args: never; Returns: boolean }
      owns_family: { Args: { fid: string }; Returns: boolean }
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

